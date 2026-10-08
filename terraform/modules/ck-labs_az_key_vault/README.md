# ck-labs_az_key_vault

RBAC-only Azure Key Vault holding ck-labs secrets (RiskShield API key). No
access policies: readers get the `Key Vault Secrets User` role, granted to the
Container App identity by `ck-labs_az_container_app`.

## Files

| File                | Contents                                              |
|---------------------|-------------------------------------------------------|
| `main.tf`           | `terraform` block (versions, `azurerm = 4.81.0`)       |
| `variables.tf`      | Location, resource group, one `vault` object, sensitive `secrets`, tags |
| `locals.tf`         | Vault name, `common_tags`                             |
| `outputs.tf`        | Vault id, name, URI, secret ids (sensitive)           |
| `vault.tf`          | `azurerm_key_vault` + `azurerm_key_vault_secret` map  |
| `README.Resources.md` | Per-resource inventory                              |

## Usage

```hcl
module "vault" {
  source              = "./modules/ck-labs_az_key_vault"
  location            = "southafricanorth"
  resource_group_name = "rg-ck-labs-dev"
  environment         = "dev"

  vault = {
    sku_name = "standard"
  }

  secrets = {
    "riskshield-api-key" = var.riskshield_api_key
  }
}
```
