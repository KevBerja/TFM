terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.14.0"
    }
  }
}

provider "vault" {
  address = "http://vault:8200"
  token = "root"
}

# Habilitar el metodo de autenticación OIDC
resource "vault_auth_backend" "oidc" {
  type = "oidc"
  path = "oidc"
  description = "OIDC Auth Method"
}

# Configuracion OIDC usando vault_generic_endpoint
resource "vault_generic_endpoint" "oidc_config" {
  path = "auth/${vault_auth_backend.oidc.path}/config"
  disable_read = true
  data_json = jsonencode({
    oidc_discovery_url = "http://keycloak:8080/realms/tfm",
    oidc_client_id     = "vault",
    oidc_client_secret = "inlumine.ual.es",
    default_role       = "default"
  })
}

# Definicion del rol para OIDC
resource "vault_generic_endpoint" "oidc_role" {
  path = "auth/${vault_auth_backend.oidc.path}/role/default"
  data_json               = jsonencode({
    allowed_redirect_uris = [
      "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
      "http://localhost:8250/ui/vault/auth/oidc/callback",
    ],
    user_claim            = "sub",
    bound_issuer          = "http://keycloak:8080/auth/realms/tfm",
    policies              = ["default"],
    ttl                   = "1h"
  })
}

# Definir la política
resource "vault_policy" "default" {
  name = "default"

  policy = <<EOF
# Permitir acceso al método de autenticación OIDC
path "auth/oidc/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Permitir acceso para interactuar con tokens de autenticación
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Permitir acceso a los caminos de autenticación y configuración del sistema
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Permitir acceso a los secretos con capacidad de escritura y lectura
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
}
