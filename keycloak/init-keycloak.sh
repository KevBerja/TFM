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
  chmod a+r "${JDBC_DRIVER_PATH}"
else
  echo "Error: No se ha cargado el controlador JDBC de PostgreSQL."
  exit 1
fi

echo "Esperando a que Postgresql esté disponible en el puerto 5432..."
while ! (echo > /dev/tcp/keycloak-db/5432) 2>/dev/null; do
  sleep 1
done
echo "Postgresql está listo. Iniciando Keycloak..."

# Iniciar Keycloak
exec /opt/keycloak/bin/kc.sh start-dev