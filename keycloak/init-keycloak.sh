#!/bin/bash

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
exec /opt/keycloak/bin/kc.sh start-dev --import-realm