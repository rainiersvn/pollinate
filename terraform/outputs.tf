# Handles the root module exposes (smoke-test URL, registry + vault refs).

output "resource_group_name" {
  description = "Environment resource group name."
  value       = azurerm_resource_group.this.name
}

output "app_name" {
  description = "Container app name."
  value       = module.container_app.name
}

output "app_fqdn" {
  description = "Latest-revision FQDN for smoke tests."
  value       = module.container_app.fqdn
}

output "registry_login_server" {
  description = "Registry login server (image prefix)."
  value       = module.registry.login_server
}

output "vault_uri" {
  description = "Vault URI for secret references."
  value       = module.vault.vault_uri
}
