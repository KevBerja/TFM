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
  url       = var.keycloak_url
  client_id = var.keycloak_client_id
  username  = var.keycloak_username
  password  = var.keycloak_password
  realm     = var.keycloak_realm
}

provider "vault" {
  address = var.vault_address
  token   = local.vault_token
}

# Realm "tfm"
resource "keycloak_realm" "tfm" {
  realm   = var.keycloak_realm_name
  enabled = var.keycloak_realm_enabled
}

# Cliente "vault"
resource "keycloak_openid_client" "vault" {
  realm_id                 = keycloak_realm.tfm.id
  client_id                = var.vault_client_id
  name                     = var.vault_client_name
  enabled                  = var.vault_client_enabled
  standard_flow_enabled    = var.vault_standard_flow_enabled
  access_type              = var.vault_access_type
  service_accounts_enabled = var.vault_service_accounts_enabled
  client_secret            = var.vault_client_secret
  valid_redirect_uris      = var.vault_valid_redirect_uris
  web_origins              = var.vault_web_origins
}

# Cliente "tfg"
resource "keycloak_openid_client" "tfg" {
  realm_id                 = keycloak_realm.tfm.id
  client_id                = var.tfg_client_id
  name                     = var.tfg_client_name
  enabled                  = var.tfg_client_enabled
  standard_flow_enabled    = var.tfg_standard_flow_enabled
  access_type              = var.tfg_access_type
  service_accounts_enabled = var.tfg_service_accounts_enabled
  valid_redirect_uris      = var.tfg_valid_redirect_uris
  client_secret            = var.tfg_client_secret
  web_origins              = var.tfg_web_origins
}

# Crear el usuario "kcv239"
resource "keycloak_user" "kcv239" {
  realm_id = keycloak_realm.tfm.id
  username = var.kcv239_username
  enabled  = var.kcv239_enabled

  initial_password {
    temporary = var.kcv239_temporary_password
    value     = var.kcv239_password_value
  }
}

# Habilitar el metodo de autenticacion OIDC
resource "vault_auth_backend" "oidc" {
  type        = var.oidc_auth_type
  path        = var.oidc_auth_path
  description = var.oidc_auth_description
}

# Habilitar el metodo de autenticacion JWT
resource "vault_auth_backend" "jwt" {
  type        = var.jwt_auth_type
  path        = var.jwt_auth_path
  description = var.jwt_auth_description
}

# Configuracion OIDC usando vault_generic_endpoint
resource "vault_generic_endpoint" "oidc_config" {
  depends_on   = [keycloak_realm.tfm]
  path         = "auth/${vault_auth_backend.oidc.path}/config"
  disable_read = false
  data_json = jsonencode({
    oidc_discovery_url = "${var.keycloak_url}/realms/tfm",
    oidc_client_id     = var.vault_client_id,
    oidc_client_secret = var.vault_client_secret,
    default_role       = var.oidc_default_role
  })
}

resource "vault_generic_endpoint" "jwt_config" {
  depends_on   = [keycloak_realm.tfm]
  path         = "auth/${vault_auth_backend.jwt.path}/config"
  disable_read = false
  data_json = jsonencode({
    oidc_discovery_url = "${var.keycloak_url}/realms/tfm",
    default_role       = var.jwt_default_role
  })
}

# Definicion del rol para OIDC vault
resource "vault_generic_endpoint" "oidc_role" {
  path = "auth/${vault_auth_backend.oidc.path}/role/default"
  data_json = jsonencode({
    allowed_redirect_uris = var.oidc_allowed_redirect_uris,
    user_claim            = var.oidc_user_claim,
    role_type             = var.oidc_role_type,
    oidc_scopes           = var.oidc_scopes,
    bound_issuer          = "${var.keycloak_url}/realms/tfm",
    policies              = var.oidc_policies,
    ttl                   = var.oidc_ttl
  })
}

# Definicion del rol para JWT vault
resource "vault_generic_endpoint" "jwt_role" {
  path = "auth/${vault_auth_backend.jwt.path}/role/default"
  data_json = jsonencode({
    allowed_redirect_uris = var.jwt_allowed_redirect_uris,
    user_claim            = var.jwt_user_claim,
    role_type             = var.jwt_role_type,
    bound_issuer          = "${var.keycloak_url}/realms/tfm",
    bound_audiences       = var.jwt_bound_audiences,
    policies              = var.jwt_policies,
    ttl                   = var.jwt_ttl
  })
}

# Politica "default" vault
resource "vault_policy" "default" {
  name   = var.vault_policy_name
  policy = var.vault_policy_content
}
