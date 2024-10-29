storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

plugin_directory = "/vault/plugins"

api_addr = "http://localhost:8200"
ui = true

disable_mlock = true