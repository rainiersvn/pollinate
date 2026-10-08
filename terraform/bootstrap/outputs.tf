# Values the Phase 5 root module needs for its azurerm backend block.

output "resource_group_name" {
  description = "State storage resource group (backend resource_group_name)."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "State storage account (backend storage_account_name)."
  value       = azurerm_storage_account.tfstate.name
}

output "dev_container_name" {
  description = "Dev state container (backend container_name for dev)."
  value       = azurerm_storage_container.dev.name
}

output "prod_container_name" {
  description = "Prod state container (backend container_name for prod)."
  value       = azurerm_storage_container.prod.name
}
