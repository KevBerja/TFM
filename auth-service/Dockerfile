FROM ubuntu:latest

# Instalacion de dependencias
RUN apt-get update && apt-get install -y curl openjdk-11-jre-headless unzip && \
    rm -rf /var/lib/apt/lists/*

# Configuracion variables de entorno para Vault y Keycloak
ENV VAULT_DEV_ROOT_TOKEN_ID=root \
    VAULT_ADDR=http://0.0.0.0:8200 \
    VAULT_API_ADDR=http://0.0.0.0:8200 \
    VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
    VAULT_DISABLE_MLOCK=true \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin

# Descarga e instalacion de Keycloak y Vault
WORKDIR /opt
RUN curl -L https://github.com/keycloak/keycloak/releases/download/19.0.3/keycloak-19.0.3.tar.gz | tar zx && \
    mv keycloak-19.0.3 keycloak
RUN curl -L https://releases.hashicorp.com/vault/1.11.12/vault_1.11.12_linux_amd64.zip -o vault.zip && \
    unzip vault.zip && \
    mv vault /usr/local/bin/ && \
    rm vault.zip

# Creacion scripts inicio Keycloak y Vault
RUN echo '#!/bin/bash\n\
nohup /usr/local/bin/vault server -dev &\n\
/opt/keycloak/bin/kc.sh start-dev\n\
' > /start.sh && chmod +x /start.sh

# Volumenes para Keycloak y Vault
VOLUME ["/opt/keycloak/data", "/vault/file"]

# Puertos de Keycloak y Vault
EXPOSE 8080 8200

CMD ["/start.sh"]