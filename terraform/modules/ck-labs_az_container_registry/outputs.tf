# Registry handles the Phase 5 root module needs (login server for the
# Container App registry block, id as the AcrPull assignment scope).

output "id" {
  description = "Registry id (AcrPull role-assignment scope)."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry login server (Container App image prefix)."
  value       = azurerm_container_registry.this.login_server
}
