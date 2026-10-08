# ck-labs_az_container_app — Container App + environment for ck-labs.
#
# terraform block lives here so the module keeps the exact Phase 4 file set
# (main / variables / locals / outputs / container_app / READMEs). The time
# provider backs the RBAC propagation guard (see container_app.tf).

terraform {
  required_version = ">= 1.3.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.81.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "= 0.13.1"
    }
  }
}
