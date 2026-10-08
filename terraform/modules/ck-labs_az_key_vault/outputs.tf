# Vault handles the Phase 5 root module needs (id as the Secrets User
# assignment scope, uri for references, secret ids for Container App refs).

output "id" {
  description = "Vault id (Secrets User role-assignment scope)."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Vault name."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Vault URI for secret references."
  value       = azurerm_key_vault.this.vault_uri
}

output "secret_ids" {
  description = "Versionless ids of the managed secrets, keyed by name."
  value       = { for k, s in azurerm_key_vault_secret.this : k => s.versionless_id }
  sensitive   = true
}
