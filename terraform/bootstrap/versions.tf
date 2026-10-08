# ck-labs Terraform bootstrap: remote-state storage for the FinSure platform.
#
# Run-once root. Backend is local (default terraform.tfstate, git-ignored):
# this root creates the Azure Storage that the Phase 5 root module then uses
# as its azurerm backend — one container per environment (dev, prod).

terraform {
  required_version = ">= 1.3.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.81.0"
    }
  }
}

provider "azurerm" {
  features {}
}
