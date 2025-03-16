locals {
    vault_keys  = jsondecode(file("${path.module}/${var.vault_token_file_path}"))
    vault_token = local.vault_keys.root_token
}