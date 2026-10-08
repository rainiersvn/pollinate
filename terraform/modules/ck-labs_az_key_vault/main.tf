# ck-labs_az_key_vault — RBAC-only Key Vault for ck-labs secrets.
#
# terraform block lives here so the module keeps the exact Phase 4 file set
# (main / variables / locals / outputs / vault / READMEs).

terraform {
  required_version = ">= 1.3.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.81.0"
    }
  }
}
