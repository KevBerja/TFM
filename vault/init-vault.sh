#!/bin/sh

# Obtener la IP del contenedor Keycloak
KEYCLOAK_IP=$(getent hosts keycloak | awk '{ print $1 }')

# Comprobar si se obtuvo una IP válida
if [ -n "$KEYCLOAK_IP" ]; then

  if grep -q 'keycloak' /etc/hosts; then
    sed -i '/ keycloak/d' /etc/hosts
    echo "Entrada de Keycloak eliminada de /etc/hosts."
  else
    echo "No se encontró ninguna entrada de Keycloak en /etc/hosts."
  fi

  # Añadir la nueva entrada al /etc/hosts de Vault
  echo "$KEYCLOAK_IP keycloak" >> /etc/hosts
  echo "Se actualizó la IP de Keycloak ($KEYCLOAK_IP) en el archivo /etc/hosts de Vault."
else
  echo "No se pudo obtener la IP de Keycloak."
fi

# Inicializacion de Vault
vault server -config=/vault/config/vault.hcl

# Ruta token root
ROOT_TOKEN_FILE="/vault/creds/root_token"

# Inicializar Vault si no está inicializado
if vault status | grep -q 'Initialized.*false'; then
  echo "Vault no está inicializado. Iniciando inicialización..."
  vault operator init -key-shares=1 -key-threshold=1 > /vault/init-output

  UNSEAL_KEY=$(grep 'Unseal Key 1:' /vault/init-output | awk '{print $NF}')
  ROOT_TOKEN=$(grep 'Initial Root Token:' /vault/init-output | awk '{print $NF}')

  # Des-sellar Vault
  vault operator unseal $UNSEAL_KEY

  # Guardar la clave de des-sellado y el token root
  mkdir -p /vault/token
  echo $UNSEAL_KEY > /vault/token/unseal_key
  echo $ROOT_TOKEN > $ROOT_TOKEN_FILE

  echo "Vault inicializado y des-sellado correctamente."
else
  echo "Vault ya está inicializado. Des-sellando..."

  # Leer la clave de des-sellado
  if [ -f /vault/token/unseal_key ]; then
    UNSEAL_KEY=$(cat /vault/token/unseal_key)
    vault operator unseal $UNSEAL_KEY
  else
    echo "Error: No se encontró la clave de des-sellado. No se puede des-sellar Vault."
    exit 1
  fi

  echo "Vault des-sellado correctamente."

  # Verificar si el token root existe
  if [ ! -f $ROOT_TOKEN_FILE ]; then
    echo "El token root no existe. Generando un nuevo token con privilegios administrativos..."

    # Generar una solicitud de token root
    vault operator generate-root -init > /vault/root-gen

    NONCE=$(grep 'Nonce' /vault/root-gen | awk '{print $NF}')

    # Proporcionar la clave de des-sellado para generar el token root
    vault operator generate-root -nonce="$NONCE" -generate-otp=false -key-shares=1 -key-threshold=1 > /vault/root-gen-continue

    ENCODED_TOKEN=$(grep 'Encoded Token' /vault/root-gen-continue | awk '{print $NF}')

    # Finalizar la generación del token root
    ROOT_TOKEN=$(vault operator generate-root -nonce="$NONCE" -decode="$ENCODED_TOKEN")

    # Guardar el nuevo token root
    echo $ROOT_TOKEN > $ROOT_TOKEN_FILE

    echo "Nuevo token root generado y almacenado."
  else
    echo "Token root existente encontrado."
  fi
fi