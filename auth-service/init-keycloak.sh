# Obtener token de administrador
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "client_id=$ADMIN_CLI_CLIENT" | jq -r '.access_token')

if [ "$TOKEN" == "null" ]; then
    echo "Error al obtener el token de administrador"
    exit 1
fi

echo "Token de administrador obtenido con éxito"

# Crear el realm HashiCorp
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "id": "hashicorp",
        "realm": "hashicorp",
        "enabled": true,
        "sslRequired": "external",
        "accessTokenLifespan": 300,
        ...
        }'

echo "Realm hashicorp creado"


# Añadir roles al realm hashicorp
curl -s -X POST "$KEYCLOAK_URL/admin/realms/hashicorp/roles" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "uma_authorization",
        "description": "UMA authorization"
        }'

curl -s -X POST "$KEYCLOAK_URL/admin/realms/hashicorp/roles" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "offline_access",
        "description": "Offline access role"
        }'

echo "Roles configurados"

# Añadir un cliente al realm hashicorp
curl -s -X POST "$KEYCLOAK_URL/admin/realms/hashicorp/clients" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "clientId": "vault",
        "directAccessGrantsEnabled": true,
        "redirectUris": [
            "*"
        ],
        "publicClient": true,
        "protocol": "openid-connect",
        "enabled": true
        }'

echo "Clientes configurados"

# Añadir un usuario al realm hashicorp
curl -s -X POST "$KEYCLOAK_URL/admin/realms/hashicorp/users" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "username": "user",
        "enabled": true,
        "emailVerified": false,
        "credentials": [{
            "type": "password",
            "value": "password",
            "temporary": false
        }],
        "realmRoles": ["uma_authorization", "offline_access"]
        }'

echo "Usuarios configurados"