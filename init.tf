terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.14.0"
    }
  }
}

provider "vault" {
  address = "http://localhost:8200"
  token   = "root"
}

# Habilitar el metodo de autenticación OIDC
resource "vault_auth_backend" "oidc" {
  type        = "oidc"
  path        = "oidc"
  description = "OIDC Auth Method"
}

# Configuracion OIDC usando vault_generic_endpoint
resource "vault_generic_endpoint" "oidc_config" {
  path = "auth/${vault_auth_backend.oidc.path}/config"

  data_json = jsonencode({
    oidc_discovery_url = "http://keycloak:8080/realms/tfm",
    oidc_client_id     = "vault",
    oidc_client_secret = "vault-client-secret",
    default_role       = "default"
  })
}

# Definicion del rol para OIDC
resource "vault_generic_endpoint" "oidc_role" {
  path = "auth/${vault_auth_backend.oidc.path}/role/default"

  data_json = jsonencode({
    allowed_redirect_uris = [
      "http://vault:8200/ui/vault/auth/oidc/oidc/callback",
      "http://localhost:8200/ui/vault/auth/oidc/oidc/callback"
    ],
    user_claim = "sub",
    policies   = ["default"],
    ttl        = "1h"
  })
}

# Definir la política
resource "vault_policy" "default" {
  name = "default"

  policy = <<EOF
    path "secret/*" {
      capabilities = ["read"]
    }
    EOF
}