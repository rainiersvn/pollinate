# Azure Container Registry for the ck-labs API image.
#
# Admin account stays disabled: the Container App pulls with its user-assigned
# managed identity (AcrPull role, wired in ck-labs_az_container_app).

resource "azurerm_container_registry" "this" {
  name                          = local.registry_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.registry.sku
  admin_enabled                 = var.registry.admin_enabled
  public_network_access_enabled = var.registry.public_network_access_enabled
  tags                          = local.common_tags
}
