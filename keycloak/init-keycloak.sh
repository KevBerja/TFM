#!/bin/bash

# Obtener IP de Vault
VAULT_IP=$(getent hosts vault | awk '{ print $1 }')
echo "Dirección IP de Vault: $VAULT_IP"

# Actualizar fichero /etc/hosts
if [ -n "$VAULT_IP" ]; then
  if grep -q 'vault' /etc/hosts; then
    sed -i '/ vault/d' /etc/hosts
    echo "Entrada de Vault eliminada de /etc/hosts."
  else
    echo "No se encontró ninguna entrada de Vault en /etc/hosts."
  fi

  echo "$VAULT_IP vault" >> /etc/hosts
  echo "Se actualizó la IP de Vault ($VAULT_IP) en el archivo /etc/hosts de Keycloak."
else
  echo "No se pudo obtener la IP de Vault."
fi


# Obtener IP de Postgres
POSTGRES_IP=$(getent hosts keycloak-db | awk '{ print $1 }')
echo "Dirección IP de Postgres: $POSTGRES_IP"

# Actualizar fichero /etc/hosts
if [ -n "$POSTGRES_IP" ]; then
  if grep -q 'keycloak-db' /etc/hosts; then
    sed -i '/ keycloak-db/d' /etc/hosts
    echo "Entrada de Postgres eliminada de /etc/hosts."
  else
    echo "No se encontró ninguna entrada de Postgres en /etc/hosts."
  fi

  echo "$PPSTGRES_IP keycloak-db" >> /etc/hosts
  echo "Se actualizó la IP de Postgres ($POSTGRES_IP) en el archivo /etc/hosts de Keycloak."
else
  echo "No se pudo obtener la IP de Postgres."
fi

# Crear el directorio de proveedores si no existe
mkdir -p /opt/keycloak/providers

# Definir la ruta y versión del controlador JDBC
JDBC_DRIVER_VERSION="42.2.23"
JDBC_DRIVER_FILE="postgresql-${JDBC_DRIVER_VERSION}.jar"
JDBC_DRIVER_PATH="/opt/keycloak/providers/${JDBC_DRIVER_FILE}"

# Verificar si el controlador ya existe
if [ -f "${JDBC_DRIVER_PATH}" ]; then
  echo "El controlador JDBC de PostgreSQL ya está presente en ${JDBC_DRIVER_PATH}."
else
  echo "Descargando el controlador JDBC de PostgreSQL versión ${JDBC_DRIVER_VERSION}..."
  curl -L "https://jdbc.postgresql.org/download/${JDBC_DRIVER_FILE}" -o "${JDBC_DRIVER_PATH}"

  # Verificar que el controlador se descargó correctamente
  if [ -f "${JDBC_DRIVER_PATH}" ]; then
    echo "Controlador JDBC descargado exitosamente."
  else
    echo "Error al descargar el controlador JDBC."
    exit 1
  fi

  chmod a+r "${JDBC_DRIVER_PATH}"
fi

# Iniciar Keycloak
exec /opt/keycloak/bin/kc.sh start --import-realm --http-enabled=true --hostname-strict=false