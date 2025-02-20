#!/bin/sh

export VAULT_ADDR='http://vault:8200'

# Esperar a que Vault este disponible
until curl -s $VAULT_ADDR/v1/sys/health > /dev/null; do
  echo "Esperando a que Vault esté disponible..."
  sleep 1
done

# Verificar si Vault esta inicializado
if [ "$(vault status -format=json | jq -r '.initialized')" = "false" ]; then
  echo "Inicializando Vault..."
  vault operator init -key-shares=1 -key-threshold=1 -format=json > /vault/data/keys.json

  UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' /vault/data/keys.json)
  ROOT_TOKEN=$(jq -r '.root_token' /vault/data/keys.json)

  # Des-sellar Vault
  vault operator unseal $UNSEAL_KEY

  echo "Vault inicializado y des-sellado."
else
  echo "Vault ya está inicializado. Des-sellando..."
  UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' /vault/data/keys.json)
  vault operator unseal $UNSEAL_KEY
  echo "Vault des-sellado."
fi