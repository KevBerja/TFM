FROM ubuntu:22.04

# Instalación de dependencias
RUN apt-get update && apt-get install -y curl openjdk-11-jre-headless unzip && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y wget && \
    wget -O /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 && \
    chmod +x /usr/local/bin/jq && \
    apt-get purge -y wget && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Configuración de variables de entorno para Vault y Keycloak
ENV VAULT_DEV_ROOT_TOKEN_ID=root \
    VAULT_ADDR=http://0.0.0.0:8200 \
    VAULT_API_ADDR=http://0.0.0.0:8200 \
    VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
    VAULT_DISABLE_MLOCK=true \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin \
    KEYCLOAK_URL=http://0.0.0.0:8080/auth

# Descarga e instalación de Keycloak y Vault
WORKDIR /opt
RUN curl -L https://github.com/keycloak/keycloak/releases/download/19.0.3/keycloak-19.0.3.tar.gz | tar zx && \
    mv keycloak-19.0.3 keycloak
RUN curl -L https://releases.hashicorp.com/vault/1.11.12/vault_1.11.12_linux_amd64.zip -o vault.zip && \
    unzip vault.zip && \
    mv vault /usr/local/bin/ && \
    rm vault.zip

COPY init-keycloak.sh /init-keycloak.sh

RUN chmod +x /init-keycloak.sh

# Creación de script de inicio para Keycloak y Vault
RUN echo '#!/bin/bash\n\
/usr/local/bin/vault server -dev &\n\
/opt/keycloak/bin/kc.sh start-dev &\n\
sleep 10\n\
/init-keycloak.sh\n\
tail -f /dev/null\n\
' > /start.sh && chmod +x /start.sh

# Volúmenes para Keycloak y Vault
# VOLUME ["/opt/keycloak/data", "/vault/file"]

# Puertos de Keycloak y Vault
# EXPOSE 8080 8200

CMD ["/start.sh"]