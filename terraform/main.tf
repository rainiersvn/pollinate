# ck-labs root module: one resource group plus the four Phase 4 children.
#
# Backend is azurerm state from the bootstrap root. The storage account name
# carries a globally-unique suffix, so it is NOT hardcoded here: read it
# from the bootstrap outputs and pass it at init time (see README.md):
#   cd bootstrap
#   terraform output resource_group_name
#   terraform output storage_account_name
#   cd ..
#   terraform init -reconfigure \
#     -backend-config="storage_account_name=<storage_account_name output>" \
#     -backend-config="container_name=tfstate-dev" \
#     -backend-config="key=dev.terraform.tfstate"
# (prod identical, with tfstate-prod / prod.terraform.tfstate.)

terraform {
  required_version = ">= 1.3.6"

  backend "azurerm" {
    resource_group_name  = "rg-ck-labs-tfstate"
    storage_account_name = "REPLACE_WITH_BOOTSTRAP_OUTPUT"
    container_name       = "tfstate-dev"
    key                  = "dev.terraform.tfstate"
  }

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

# Single provider block for the whole composition. Child modules declare
# required_providers only and inherit this configuration.

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Optional environment lock: off ("") in dev, "CanNotDelete" in prod.

resource "azurerm_management_lock" "this" {
  count      = var.lock_type == "" ? 0 : 1
  name       = "${local.resource_group_name}-lock"
  scope      = azurerm_resource_group.this.id
  lock_level = var.lock_type
  notes      = "ck-labs ${var.environment} resource lock."
}

module "observability" {
  source              = "./modules/ck-labs_az_observability"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name_prefix         = var.name_prefix
  environment         = var.environment
  workspace           = var.workspace
  insights            = var.insights
  tags                = local.common_tags
}

module "registry" {
  source              = "./modules/ck-labs_az_container_registry"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name_prefix         = var.name_prefix
  environment         = var.environment
  registry            = var.registry
  tags                = local.common_tags
}

module "vault" {
  source              = "./modules/ck-labs_az_key_vault"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name_prefix         = var.name_prefix
  environment         = var.environment
  vault               = var.vault
  secrets             = var.secrets
  tags                = local.common_tags
}

module "container_app" {
  source              = "./modules/ck-labs_az_container_app"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name_prefix         = var.name_prefix
  environment         = var.environment

  # Cross-module wiring: workspace for the environment, registry for the
  # image pull + AcrPull scope, vault for the Secrets User scope + refs.
  log_analytics_workspace_id = module.observability.workspace_id
  registry_login_server      = module.registry.login_server
  registry_id                = module.registry.id
  key_vault_id               = module.vault.id
  key_vault_secrets          = module.vault.secret_ids

  image      = var.image
  app        = var.app
  scaling    = var.scaling
  env_vars   = var.env_vars
  secret_env = var.secret_env
  tags       = local.common_tags

  # Explicit ordering on observability (implicit via workspace_id too), so
  # the environment never races workspace creation. The 60s RBAC propagation
  # guard already lives inside the child (time_sleep.rbac_propagation).
  depends_on = [module.observability]
}
