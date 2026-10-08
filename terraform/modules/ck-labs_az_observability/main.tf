# ck-labs_az_observability — Log Analytics + Application Insights for ck-labs.
#
# terraform block lives here so the module keeps the exact Phase 4 file set
# (main / variables / locals / outputs / observability / READMEs).

terraform {
  required_version = ">= 1.3.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.81.0"
    }
  }
}
