# App handles the Phase 5 root module needs (URL for smoke tests, identity
# for any extra role grants, environment id for jobs/extensions).

output "id" {
  description = "Container app id."
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Container app name."
  value       = azurerm_container_app.this.name
}

output "fqdn" {
  description = "Latest-revision FQDN for smoke tests."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "environment_id" {
  description = "Container Apps environment id."
  value       = azurerm_container_app_environment.this.id
}

output "identity_id" {
  description = "User-assigned identity id (registry block, extra grants)."
  value       = azurerm_user_assigned_identity.this.id
}

output "identity_principal_id" {
  description = "Identity principal id (role-assignment subject)."
  value       = azurerm_user_assigned_identity.this.principal_id
}
