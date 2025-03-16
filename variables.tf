variable "keycloak_username" {
  description = "Username for Keycloak"
  type        = string
}

variable "keycloak_password" {
  description = "Password for Keycloak"
  type        = string
  sensitive   = true
}

variable "vault_client_secret" {
  description = "Client secret for Vault"
  type        = string
  sensitive   = true
}

variable "tfg_client_secret" {
  description = "Client secret for TFG"
  type        = string
  sensitive   = true
}

variable "keycloak_url" {
  description = "URL for Keycloak"
  type        = string
}

variable "keycloak_client_id" {
  description = "Client ID for Keycloak"
  type        = string
}

variable "keycloak_realm" {
  description = "Realm for Keycloak"
  type        = string
}

variable "vault_address" {
  description = "Address for Vault"
  type        = string
}

variable "vault_token_file_path" {
  description = "Ruta al archivo JSON que contiene el root_token de Vault"
  default     = "vault/volume/data/keys.json"
  type        = string
}

variable "keycloak_realm_name" {
  description = "Name of the Keycloak realm"
  type        = string
}

variable "keycloak_realm_enabled" {
  description = "Whether the Keycloak realm is enabled"
  type        = bool
}

variable "vault_client_id" {
  description = "Client ID for Vault"
  type        = string
}

variable "vault_client_name" {
  description = "Client name for Vault"
  type        = string
}

variable "vault_client_enabled" {
  description = "Whether the Vault client is enabled"
  type        = bool
}

variable "vault_standard_flow_enabled" {
  description = "Whether the standard flow is enabled for Vault"
  type        = bool
}

variable "vault_access_type" {
  description = "Access type for Vault"
  type        = string
}

variable "vault_service_accounts_enabled" {
  description = "Whether service accounts are enabled for Vault"
  type        = bool
}

variable "vault_valid_redirect_uris" {
  description = "Valid redirect URIs for Vault"
  type        = list(string)
}

variable "vault_web_origins" {
  description = "Web origins for Vault"
  type        = list(string)
}

variable "tfg_client_id" {
  description = "Client ID for TFG"
  type        = string
}

variable "tfg_client_name" {
  description = "Client name for TFG"
  type        = string
}

variable "tfg_client_enabled" {
  description = "Whether the TFG client is enabled"
  type        = bool
}

variable "tfg_standard_flow_enabled" {
  description = "Whether the standard flow is enabled for TFG"
  type        = bool
}

variable "tfg_access_type" {
  description = "Access type for TFG"
  type        = string
}

variable "tfg_service_accounts_enabled" {
  description = "Whether service accounts are enabled for TFG"
  type        = bool
}

variable "tfg_valid_redirect_uris" {
  description = "Valid redirect URIs for TFG"
  type        = list(string)
}

variable "tfg_web_origins" {
  description = "Web origins for TFG"
  type        = list(string)
}

variable "kcv239_username" {
  description = "Username for kcv239"
  type        = string
}

variable "kcv239_enabled" {
  description = "Whether kcv239 is enabled"
  type        = bool
}

variable "kcv239_temporary_password" {
  description = "Whether the initial password for kcv239 is temporary"
  type        = bool
}

variable "kcv239_password_value" {
  description = "Initial password value for kcv239"
  type        = string
  sensitive   = true
}

variable "oidc_auth_type" {
  description = "OIDC auth type"
  type        = string
}

variable "oidc_auth_path" {
  description = "OIDC auth path"
  type        = string
}

variable "oidc_auth_description" {
  description = "OIDC auth description"
  type        = string
}

variable "jwt_auth_type" {
  description = "JWT auth type"
  type        = string
}

variable "jwt_auth_path" {
  description = "JWT auth path"
  type        = string
}

variable "jwt_auth_description" {
  description = "JWT auth description"
  type        = string
}

variable "oidc_default_role" {
  description = "Default role for OIDC"
  type        = string
}

variable "jwt_default_role" {
  description = "Default role for JWT"
  type        = string
}

variable "oidc_allowed_redirect_uris" {
  description = "Allowed redirect URIs for OIDC"
  type        = list(string)
}

variable "oidc_user_claim" {
  description = "User claim for OIDC"
  type        = string
}

variable "oidc_role_type" {
  description = "Role type for OIDC"
  type        = string
}

variable "oidc_scopes" {
  description = "Scopes for OIDC"
  type        = string
}

variable "oidc_policies" {
  description = "Policies for OIDC"
  type        = list(string)
}

variable "oidc_ttl" {
  description = "TTL for OIDC"
  type        = string
}

variable "jwt_allowed_redirect_uris" {
  description = "Allowed redirect URIs for JWT"
  type        = list(string)
}

variable "jwt_user_claim" {
  description = "User claim for JWT"
  type        = string
}

variable "jwt_role_type" {
  description = "Role type for JWT"
  type        = string
}

variable "jwt_bound_audiences" {
  description = "Bound audiences for JWT"
  type        = list(string)
}

variable "jwt_policies" {
  description = "Policies for JWT"
  type        = list(string)
}

variable "jwt_ttl" {
  description = "TTL for JWT"
  type        = string
}

variable "vault_policy_name" {
  description = "Name of the Vault policy"
  type        = string
}

variable "vault_policy_content" {
  description = "Content of the Vault policy"
  type        = string
}
