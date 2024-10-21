#!/bin/sh

# Obtener la IP del contenedor Keycloak
KEYCLOAK_IP=$(getent hosts keycloak | awk '{ print $1 }')

# Comprobar si se obtuvo una IP válida
if [ -n "$KEYCLOAK_IP" ]; then
  # Añadir la entrada al /etc/hosts de Vault
  echo "$KEYCLOAK_IP keycloak" >> /etc/hosts
  echo "$KEYCLOAK_IP localhost" >> /etc/hosts
  echo "Se añadió la IP de Keycloak ($KEYCLOAK_IP) al archivo /etc/hosts de Vault."
else
  echo "No se pudo obtener la IP de Keycloak."
fi

# Ejecutar el servidor de Vault
vault server -dev -dev-listen-address=0.0.0.0:8200