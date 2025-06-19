import sys
import logging
import json
import requests
import jwt 
import os
import shutil
import joblib as jb
import traceback as tr
import requests as rq
import pandas as pd
import numpy as np
import mysql.connector

from flask import Flask, request, jsonify, render_template, url_for, redirect, session, flash, send_file
from flask_session import Session
from jwt import PyJWKClient
from werkzeug.utils import secure_filename
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from flask_oidc import OpenIDConnect

app = Flask(__name__)
app.secret_key = 'kcv239LogisticRegression'

# Configuracion de OIDC
app.config.update({
    'OIDC_CLIENT_SECRETS': './client_secrets.json',
    'OIDC_ID_TOKEN_COOKIE_SECURE': False,
    'OIDC_SCOPES': ['openid'],
    'OIDC_INTROSPECTION_AUTH_METHOD': 'client_secret_post',
    'SESSION_TYPE': 'filesystem',
    'SESSION_FILE_DIR': '/tmp/flask_session',
    'SESSION_PERMANENT': False
})

Session(app)

with open(app.config['OIDC_CLIENT_SECRETS'], 'r') as f:
    CLIENT_SECRETS = json.load(f)

KEYCLOAK_URL = "http://keycloak:8080"
REALM = "tfm"
CLIENT_ID = CLIENT_SECRETS.get('web', CLIENT_SECRETS).get('client_id')
JWKS_URL = f"{KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/certs"
jwk_client = PyJWKClient(JWKS_URL)

oidc = OpenIDConnect(app)

# Permisos
REQUIRED_PERMISSIONS = {
    'admin_dashboard':   ['admin'],
    'upload_file':       ['default'],
    'setModel':          ['default'],
    'wipe':              ['default'],
    'train':             ['default'],
    'predict':           ['default'],
    'predict_form':      ['default'],
    'predictMassive':    ['default'],
    'token_debug':       ['default']
}

PUBLIC_ENDPOINTS = ('static', 'favicon.ico', 'login', 'logout')

@app.before_request
def check_token_JWT():
    # 1) Verificar si el endpoint es una ruta no protegida
    if request.endpoint in PUBLIC_ENDPOINTS or request.endpoint or request.path.startswith('/authorize') is None:
        return

    # 2) Comprobar si hay en la cabecera un bearer token
    auth_hdr = request.headers.get('Authorization', '').strip()
    access_token = None
    if auth_hdr:
        auth_hdr_parts = auth_hdr.split()
        access_token = auth_hdr_parts[-1] 

        # 3) Decodificar y verificar JWT
        try:
            signing_key = jwk_client.get_signing_key_from_jwt(access_token).key
            decoded = jwt.decode(
                access_token,
                signing_key,
                algorithms=["RS256"],
                audience=CLIENT_ID,
                options={"verify_exp": True, "verify_aud": False}
            )
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Unauthorized", "reason": "token_expired"}), 401
        except Exception as e:
            print("[DEBUG] Error al decodificar JWT:", e, flush=True)
            return jsonify({"error": "Unauthorized", "reason": "invalid_token"}), 401

        # 4) Extraer roles de realm_access y resource_access
        roles = []
        roles += decoded.get('realm_access', {}).get('roles', [])
        for acceso in decoded.get('resource_access', {}).values():
            roles += acceso.get('roles', [])
        print(f"[DEBUG] Roles decodificados para '{request.endpoint}': {roles}", flush=True)

    else:
        if oidc.user_loggedin:
            # Sesion valida
            return
        # No hay sesion se redirecciona login OIDC
        return redirect(url_for('login', next=request.url))

    # 5) Si no hay permisos previamente configurados para el endpoint denegar acceso
    if request.method in ('GET', 'POST', 'DELETE', 'PUT') and request.endpoint not in REQUIRED_PERMISSIONS:
        return jsonify({
            "error":   "Forbidden",
            "message": f"No hay permisos configurados para '{request.endpoint}'"
        }), 403

    # 6) Comprobar permisos configurados
    permisos = REQUIRED_PERMISSIONS.get(request.endpoint, [])
    if permisos and not any(r in roles for r in permisos):
        return jsonify({
            "error": "Forbidden",
            "required_permissions": permisos
        }), 403
        
    
@app.route('/token_debug', methods=['GET', 'POST'])
@oidc.require_login
def token_debug():
    debug_info = {
        "info": "Info de debug"
    }
    
    try:
        # Obtener token de acceso del proveedor OIDC
        access_token = oidc.get_access_token()
        debug_info["Access_Token_OIDC_Provider_Get_Method"] = f"{access_token}" if access_token else "No disponible"
        
        # Obtener informacion del usuario
        if hasattr(oidc, 'user_getinfo'):
            user_info = oidc.user_getinfo(['email', 'sub', 'preferred_username'])
            debug_info["user_info"] = user_info
        
        # Obtener detalles de la sesion OIDC
        if hasattr(oidc, '_get_token_info'):
            token_info = oidc._get_token_info()
            if token_info:
                debug_info["token_info"] = {k: v for k, v in token_info.items() if k != 'access_token'}
                if 'access_token' in token_info:
                    debug_info["Access_Token_Session_Get_Method"] = f"{token_info['access_token']}"
        
        # Obtener token de sesion Flask
        if 'oidc_id_token' in session:
            debug_info["id_token_in_session"] = True
        
        return jsonify(debug_info)
    
    except Exception as e:
        return jsonify({
            "error": str(e),
            "trace": tr.format_exc()})
    
@app.route('/vault_login')
@oidc.require_login
def vault_login():
     # 1. Obtener el token de acceso de Keycloak (OIDC)
    access_token = oidc.get_access_token()
    if not access_token:
        flash("No se encontró el token OIDC.")
        return redirect(url_for('home'))

    # 2. Intercambiar el token OIDC por un token de Vault a través del endpoint JWT
    vault_url = "http://vault:8200/v1/auth/jwt/login"
    payload = {
        "jwt": access_token,
        "role": "default"
    }

    try:
        response = rq.post(vault_url, json=payload)
        if response.status_code == 200:
            vault_data = response.json()
            if "auth" in vault_data and "client_token" in vault_data["auth"]:
                vault_token = vault_data["auth"]["client_token"]
                # Guardar el token de Vault en la sesión
                session["vault_token"] = vault_token
                flash("Autenticación en Vault (JWT) completada con éxito.")
            else:
                flash(f"Formato de respuesta de Vault inesperado: {vault_data}")
        else:
            flash(f"Fallo en la autenticación en Vault (HTTP {response.status_code}): {response.text}")
    except Exception as e:
        flash(f"Error al conectar con Vault: {str(e)}")

    return redirect(url_for('home'))

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/login')
def login():
    next_url = request.args.get('next') or url_for('home')
    return oidc.redirect_to_auth_server(next_url)

@app.route('/logout')
def logout():
    oidc.logout()
    flash("Sesión cerrada")
    return redirect(url_for('home'))

@app.route('/loadInitCSV', methods=['GET'])
@oidc.require_login
def upload_file():
    return render_template('subida_fichero.html')

@app.route('/uploadInitCSV', methods=['POST'])
def uploader():
    if request.method == 'POST':
        file_form = request.files['file_request']
        file = secure_filename(file_form.filename)

        filename = file.split('.')
        f_name = filename[0]
        f_extension = filename[-1]

        if (f_name != "train" and f_extension != "csv"):
            flash("ERROR - Archivo no válido. El fichero de datos de entrenamiento debe estar en formato .csv con el nombre --train.csv--")

            return redirect('/loadInitCSV')

        
        os.makedirs('./static/model_temp', exist_ok=True)
        file_form.save(os.path.join('', 'static/model_temp/' + file))

        flash("Archivo de datos subido con éxito")

        return redirect('/loadInitCSV')


@app.route('/loadModel', methods=['GET'])
@oidc.require_login
def loadModel():
    try:
        mydb = mysql.connector.connect(
            host="db",
            user="root",
            password="admin",
            database="mlaas")

        mycursor = mydb.cursor()

        mycursor.execute("SELECT nombre, tipo, url FROM modelos WHERE tipo = 'Logistic Regression'")

        myresult = mycursor.fetchall()

        return render_template('cargar_modelo.html', rows=myresult)
    
    except Exception as e:
        flash("ERROR - No se han podido obtener la lista de modelos de la base de datos")

        return render_template('cargar_modelo.html')


@app.route('/setModel', methods=['POST'])
def setModel():
    if request.method == 'POST':
        json_values = list(request.form.values())
        model_name = json_values[0]
        
        try:
            shutil.copy('./static/models/' + model_name + '/train.csv', './static/model_temp/train.csv')
            shutil.copy('./static/models/' + model_name + '/model.pkl', './static/model_temp/model.pkl')
            shutil.copy('./static/models/' + model_name + '/model_columns.pkl', './static/model_temp/model_columns.pkl') 

            flash("Modelo " + model_name + " descargado correctamente")

            return redirect('/loadModel')

        except Exception as e:
            folder_path = './static/model_temp' 
            
            for file_object in os.listdir(folder_path): 
                file_object_path = os.path.join(folder_path, file_object) 
                        
                if os.path.isfile(file_object_path): 
                    os.unlink(file_object_path) 
                else: 
                    shutil.rmtree(file_object_path)

            flash("ERROR - No se ha podido descargar el modelo: " + model_name)

            return redirect('/loadModel')



@app.route('/deleteModel', methods=['GET', 'DELETE'])
@oidc.require_login
def wipe():
    try:
        folder_path = './static/model_temp' 
        
        for file_object in os.listdir(folder_path): 
            file_object_path = os.path.join(folder_path, file_object) 
            
            if os.path.isfile(file_object_path): 
                os.unlink(file_object_path) 
            else: 
                shutil.rmtree(file_object_path)
        
        flash("Modelo eliminado correctamente")
        
        return redirect('/')

    except Exception as e:
        flash("ERROR - No se ha podido eliminar el modelo. Por favor, verifica si el modelo que desea eliminar existe")
        
        return redirect('/')


@app.route('/formTrain', methods=['GET'])
@oidc.require_login
def formTrain():
    return render_template('train.html')

@app.route('/train', methods=['POST'])
def train():
    if request.method == 'POST':
        model = list(request.form.values())
        model_name = model[0]

        if os.path.exists('./static/model_temp/train.csv'):
            if os.path.exists('./static/models/' + model_name):
                flash("Existe un modelo con el nombre '" + model_name + "'. Por favor, utilice otro nombre")
                  
                return redirect('/formTrain')
                
            else:   
                os.makedirs('./static/models/' + model_name, exist_ok=True)

            df = pd.read_csv('./static/model_temp/train.csv', encoding='latin-1')
            include = [str(x) for x in df.columns]  
            dependent_variable = include[-1]
            df_ = df[include]

            categoricals = []

            for col, col_type in df_.dtypes.items():        
                if col_type == 'O':
                    categoricals.append(col)
                else:
                    df_[col].fillna(0, inplace=True)

            df_ohe = pd.get_dummies(df_, columns=categoricals, dummy_na=True)

            x = df_ohe[df_ohe.columns.difference([dependent_variable])]
            y = df_ohe[dependent_variable]

            model_columns = list(x.columns)
            clf = LogisticRegression()
                
            # Test Data and Training Data
            x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.33, random_state=42)
            clf.fit(x_train, y_train)

            # Accuracy model score
            y_pred = clf.predict(x_test)
            score = accuracy_score(y_pred, y_test)

            try:
                jb.dump(clf, './static/model_temp/model.pkl')
                jb.dump(model_columns, './static/model_temp/model_columns.pkl')

                flash("Modelo entrenado correctamente")
                
            except Exception as e:
                folder_path = './static/model_temp' 
        
                for file_object in os.listdir(folder_path): 
                    file_object_path = os.path.join(folder_path, file_object) 
                    
                    if os.path.isfile(file_object_path): 
                        os.unlink(file_object_path) 
                    else: 
                        shutil.rmtree(file_object_path)

                flash("ERROR - Ha ocurrido un problema durante el entrenamiento")
                        
                return redirect('/formTrain')

            try:
                shutil.copy('./static/model_temp/train.csv', './static/models/' + model_name + '/train.csv')
                shutil.copy('./static/model_temp/model.pkl', './static/models/' + model_name + '/model.pkl')
                shutil.copy('./static/model_temp/model_columns.pkl', './static/models/' + model_name + '/model_columns.pkl')

                try:
                    mydb = mysql.connector.connect(
                        host="db",
                        user="root",
                        password="admin",
                        database="mlaas")

                    mycursor = mydb.cursor()

                    sql = "INSERT INTO modelos (tipo, nombre, url) VALUES (%s, %s, %s)"
                    val = ("Logistic Regression", model_name, './static/models/' + model_name)
                    
                    mycursor.execute(sql, val)

                    mydb.commit()

                    flash("Modelo '" + model_name + "' guardado en la base de datos correctamente")
                                
                    return redirect('/formTrain')
                        
                except Exception as ex:
                    shutil.rmtree('./static/models/' + model_name)

                    flash("ERROR - No se ha podido guardar el modelo: " + model_name +". Por favor, vuelva de nuevo más tarde")

                    return redirect('/formTrain')

                
            except Exception as exc:
                shutil.rmtree('./static/models/' + model_name)

                flash("ERROR - No se ha podido guardar el modelo: " + model_name +". Por favor, vuelva de nuevo más tarde")
                        
                return redirect('/formTrain')

        else:
            flash("Es necesario subir un modelo de datos")

            return redirect('/formTrain')



@app.route('/predict', methods=['POST'])
def predict():
    if request.method == 'POST':
        clf = jb.load('./static/model_temp/model.pkl')
        model_columns = jb.load('./static/model_temp/model_columns.pkl')
        if clf:
            try:
                json_ = request.json
                query = pd.DataFrame(json_)
                query = query.reindex(columns=model_columns, fill_value=0)
                prediction = clf.predict(query)

                return jsonify({"prediction": str(prediction)})
            except Exception as e:

                return jsonify({'error': str(e), 'trace': tr.format_exc()})
        else:
            return "ERROR - Se necesita primero subir el fichero de datos para entrenamiento y entrenar después al modelo"


@app.route('/load_predict_form', methods=['GET'])
@oidc.require_login
def load_form():
    try:
        df = pd.read_csv('./static/model_temp/train.csv', encoding='latin-1')
        columns = [str(x) for x in df.columns]
        columns.pop()

        return render_template('formulario_predict.html', columns=columns)
    
    except Exception as e:
        flash("Es necesario subir y entrenar un modelo o cargar un modelo existente")

        return redirect('/')
    

@app.route('/predict_form', methods=['POST'])
def predict_form():
    if request.method == 'POST':
        clf = jb.load('./static/model_temp/model.pkl')
        model_columns = jb.load('./static/model_temp/model_columns.pkl')
        
        if clf:
            try:        
                keys = list(request.form)
                values = list(request.form.values())

                json_ = {}
                iter = 0

                for v in values:
                    if v.isdigit():
                        json_[keys[iter]] = int(v)
                        iter = iter + 1
                        continue
                    if v.find(".") != -1:
                        vx = v.split(".")

                        if vx[0].isdigit() == True and vx[1].isdigit() == True:
                            json_[keys[iter]] = float(v)
                            iter = iter + 1
                            continue
                        else:
                            json_[keys[iter]] = v
                            iter = iter + 1
                            continue 
                    else:
                        json_[keys[iter]] = v
                        iter = iter + 1

                query = [json_]
                query = pd.get_dummies(pd.DataFrame(query))
                query = query.reindex(columns=model_columns, fill_value=0)
                prediction = clf.predict(query)

                df = pd.read_csv('./static/model_temp/train.csv', encoding='latin-1')
                columns = [str(x) for x in df.columns]
                columns.pop()
                
                if prediction[0] == 1:  
                    flash("Predicción realizada con éxito")

                    return render_template('formulario_predict.html', prediction=prediction[0], columns=columns)

                if prediction[0] == 0:
                    flash("Predicción realizada con éxito")

                    return render_template('formulario_predict.html', prediction=prediction[0], columns=columns)                

            except Exception as e:
                flash("ERROR - La predicción falló. Por favor, revise los datos introducidos")

                return redirect('/load_predict_form')

        else:
            flash("ERROR - Debe entrenar primero un modelo")

            return redirect('/load_predict_form')



@app.route('/loadCSVToPredict', methods=['GET'])
@oidc.require_login
def uploadMassive():
    try:
        df = pd.read_csv('./static/model_temp/train.csv', encoding='latin-1')
        columns = [str(x) for x in df.columns]
        columns.pop()

        return render_template('prediccion_masiva.html')
    
    except Exception as e:
        flash("Es necesario subir y entrenar un modelo o cargar un modelo existente")

        return redirect('/')


@app.route('/predictMassive', methods=['POST'])
def predictMassive():
    if request.method == 'POST':
        file_form = request.files['file_request']
        file = secure_filename(file_form.filename)
        filename = file.split('.')
        f_extension = filename[-1]

        if (f_extension != "csv"):
            flash("ERROR - Archivo no válido. Suba un fichero en formato .csv correcto")
            
            return redirect('/loadCSVToPredict')

        file_form.save(os.path.join('', file))
        
        df = pd.read_csv(file, encoding='latin-1')
        include = [str(x) for x in df.columns]  
        df_ = df[include]

        categoricals = []

        for col, col_type in df_.dtypes.items():        
            if col_type == 'O':
                categoricals.append(col)
            else:
                df_[col].fillna(0, inplace=True)

        query = pd.get_dummies(df_, columns=categoricals, dummy_na=True)

        clf = jb.load('./static/model_temp/model.pkl')

        os.remove(file)

        if clf:
            try:
                prediction = list(clf.predict(query))
                prediction_str = [str(i) for i in prediction]
                
                query['predict'] = prediction_str
                query.to_csv('predict.csv', header=True, index=False)

                return send_file('predict.csv', as_attachment=True, attachment_filename='predict.csv')
            
            except Exception as e:
                flash("ERROR - Falló la predicción del fichero de datos")

                return redirect('/loadCSVToPredict')
            
        else:
            flash("ERROR - Es necesario entrenar primero el modelo")
            
            return redirect('/loadCSVToPredict')



if __name__ == '__main__':
    app.run(debug=False, port=5001, host="0.0.0.0")