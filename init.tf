terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 3.6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.14.0"
    }
  }
}

provider "keycloak" {
  url       = "http://keycloak:8080"
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  realm     = "master"
}

provider "vault" {
  address = "http://vault:8200"
  token = jsondecode(file("${path.module}/vault/volume/data/keys.json")).root_token
}

# Realm "tfm"
resource "keycloak_realm" "tfm" {
  realm   = "tfm"
  enabled = true
}

# Cliente "vault"
resource "keycloak_openid_client" "vault" {
  realm_id                 = keycloak_realm.tfm.id
  client_id                = "vault"
  name                     = "vault"
  enabled                  = true
  standard_flow_enabled    = true
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
  client_secret            = "inlumine.ual.es"
  valid_redirect_uris      = [
    "http://vault:8200/*",
    "http://localhost:8200/*",
    "http://vault:8250/*",
    "http://localhost:8250/*",
    "https://oauth.pstmn.io/v1/callback"
  ]
  web_origins = ["*"]
}

# Cliente "tfg"
resource "keycloak_openid_client" "tfg" {
  realm_id                 = keycloak_realm.tfm.id
  client_id                = "tfg"
  name                     = "tfg"
  enabled                  = true
  standard_flow_enabled    = true
  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
  valid_redirect_uris      = [
    "http://localhost:5000/*", 
    "http://localhost:5001/*",
    "http://localhost:5002/*"]
  client_secret            = "inlumine.ual.es"
  web_origins              = ["*"]
}

# Crear el usuario "kcv239"
resource "keycloak_user" "kcv239" {
  realm_id = keycloak_realm.tfm.id
  username = "kcv239"
  enabled  = true

  initial_password {
    temporary = false
    value     = "inlumine.ual.es"
  }
}

# Habilitar el metodo de autenticacion OIDC
resource "vault_auth_backend" "oidc" {
  type = "oidc"
  path = "oidc"
  description = "OIDC Auth Method"
}

# Habilitar el metodo de autenticacion JWT
resource "vault_auth_backend" "jwt" {
  type = "jwt"
  path = "jwt"
  description = "JWT Auth Method"
}

# Configuracion OIDC usando vault_generic_endpoint
resource "vault_generic_endpoint" "oidc_config" {
  depends_on   = [ keycloak_realm.tfm ]
  path         = "auth/${vault_auth_backend.oidc.path}/config"
  disable_read = false
  data_json    = jsonencode({
    oidc_discovery_url = "http://keycloak:8080/realms/tfm",
    oidc_client_id     = "vault",
    oidc_client_secret = "inlumine.ual.es",
    default_role       = "default"
  })
}

resource "vault_generic_endpoint" "jwt_config" {
  depends_on   = [ keycloak_realm.tfm ]
  path         = "auth/${vault_auth_backend.jwt.path}/config"
  disable_read = false
  data_json    = jsonencode({
    oidc_discovery_url = "http://keycloak:8080/realms/tfm",
    default_role       = "default"
  })
}

# Definicion del rol para OIDC vault
resource "vault_generic_endpoint" "oidc_role" {
  path = "auth/${vault_auth_backend.oidc.path}/role/default"
  data_json               = jsonencode({
    allowed_redirect_uris = [
      "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
      "http://localhost:8250/ui/vault/auth/oidc/callback",
      "http://vault:8200/ui/vault/auth/oidc/oidc/callback",
      "http://vault:8250/ui/vault/auth/oidc/callback",
      "https://oauth.pstmn.io/v1/callback"
    ],
    user_claim            = "sub",
    role_type             = "oidc",
    oidc_scopes           = "openid",
    bound_issuer          = "http://keycloak:8080/realms/tfm",
    policies              = ["default"],
    ttl                   = "1h"
  })
}

# Definicion del rol para JWT vault
resource "vault_generic_endpoint" "jwt_role" {
  path = "auth/${vault_auth_backend.jwt.path}/role/default"
  data_json = jsonencode({
    allowed_redirect_uris = [
      "http://localhost:8200/ui/vault/auth/jwt/callback",
      "http://localhost:8250/ui/vault/auth/jwt/callback",
      "http://vault:8200/ui/vault/auth/jwt/callback",
      "http://vault:8250/ui/vault/auth/jwt/callback",
      "https://oauth.pstmn.io/v1/callback"
    ],
    user_claim         = "sub",
    role_type          = "jwt",
    bound_issuer       = "http://keycloak:8080/realms/tfm",
    bound_audiences    = ["account"],
    policies           = ["default"],
    ttl                = "1h"
  })
}

# Politica "default" vault
resource "vault_policy" "default" {
  name = "default" 
  policy = <<EOF
    path "*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    EOF
}