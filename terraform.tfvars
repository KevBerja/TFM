keycloak_url           = "http://keycloak:8080"
keycloak_client_id     = "admin-cli"
keycloak_username      = "admin"
keycloak_password      = "admin"
keycloak_realm         = "master"
vault_address          = "http://vault:8200"
vault_client_secret    = "inlumine.ual.es"
tfg_client_secret      = "inlumine.ual.es"
keycloak_realm_name    = "tfm"
keycloak_realm_enabled = true

vault_client_id                = "vault"
vault_client_name              = "vault"
vault_client_enabled           = true
vault_standard_flow_enabled    = true
vault_access_type              = "CONFIDENTIAL"
vault_service_accounts_enabled = true
vault_valid_redirect_uris = [
  "http://vault:8200/*",
  "http://localhost:8200/*",
  "http://vault:8250/*",
  "http://localhost:8250/*",
  "https://oauth.pstmn.io/v1/callback"
]
vault_web_origins = ["*"]

tfg_client_id                = "tfg"
tfg_client_name              = "tfg"
tfg_client_enabled           = true
tfg_standard_flow_enabled    = true
tfg_access_type              = "CONFIDENTIAL"
tfg_service_accounts_enabled = true
tfg_valid_redirect_uris = [
  "http://localhost:5000/*",
  "http://localhost:5001/*",
  "http://localhost:5002/*"
]
tfg_web_origins = ["*"]

kcv239_username           = "kcv239"
kcv239_enabled            = true
kcv239_temporary_password = false
kcv239_password_value     = "inlumine.ual.es"

oidc_auth_type        = "oidc"
oidc_auth_path        = "oidc"
oidc_auth_description = "OIDC Auth Method"

jwt_auth_type        = "jwt"
jwt_auth_path        = "jwt"
jwt_auth_description = "JWT Auth Method"

oidc_default_role = "default"
jwt_default_role  = "default"

oidc_allowed_redirect_uris = [
  "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
  "http://localhost:8250/ui/vault/auth/oidc/callback",
  "http://vault:8200/ui/vault/auth/oidc/oidc/callback",
  "http://vault:8250/ui/vault/auth/oidc/callback",
  "https://oauth.pstmn.io/v1/callback"
]
oidc_user_claim = "sub"
oidc_role_type  = "oidc"
oidc_scopes     = "openid"
oidc_policies   = ["default"]
oidc_ttl        = "1h"

jwt_allowed_redirect_uris = [
  "http://localhost:8200/ui/vault/auth/jwt/callback",
  "http://localhost:8250/ui/vault/auth/jwt/callback",
  "http://vault:8200/ui/vault/auth/jwt/callback",
  "http://vault:8250/ui/vault/auth/jwt/callback",
  "https://oauth.pstmn.io/v1/callback"
]
jwt_user_claim      = "sub"
jwt_role_type       = "jwt"
jwt_bound_audiences = ["account"]
jwt_policies        = ["default"]
jwt_ttl             = "1h"

vault_policy_name    = "default"
vault_policy_content = <<EOF
  path "*" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }
EOF
