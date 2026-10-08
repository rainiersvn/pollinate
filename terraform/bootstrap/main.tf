# One resource group + one storage account + one private container per
# environment. KISS: a single LRS account holds both dev and prod state;
# environments stay isolated by container + backend key, not by account.

locals {
  # Storage accounts allow lowercase alphanumerics only: "ck-labs" -> "cklabs".
  slug = lower(replace(var.project, "-", ""))
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${var.project}-tfstate"
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "${local.slug}tfstate${var.storage_suffix}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "dev" {
  name                  = "tfstate-dev"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "prod" {
  name                  = "tfstate-prod"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
