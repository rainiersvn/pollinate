# RBAC-only Key Vault for ck-labs secrets (e.g. the RiskShield API key).
#
# No access policies: the Container App identity gets Key Vault Secrets User
# via role assignment (wired in ck-labs_az_container_app). Tenant comes from
# the ambient client config so the root module passes no tenant id.

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = local.vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.vault.sku_name
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = var.vault.soft_delete_retention_days
  purge_protection_enabled      = var.vault.purge_protection_enabled
  public_network_access_enabled = var.vault.public_network_access_enabled
  tags                          = local.common_tags
}

# Optional seed secrets. Prefer pipeline-managed values in real use; these
# exist so dev has a working vault reference on first apply. Keys are secret
# names (not sensitive); values stay sensitive end to end.
resource "azurerm_key_vault_secret" "this" {
  for_each     = nonsensitive(var.secrets)
  name         = each.key
  value        = sensitive(each.value)
  key_vault_id = azurerm_key_vault.this.id
}
