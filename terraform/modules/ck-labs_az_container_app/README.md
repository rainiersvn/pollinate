# ck-labs_az_container_app

Container App running the ck-labs API on its own Consumption environment. The
module owns the app identity and both role grants (`AcrPull` on the registry,
`Key Vault Secrets User` on the vault), so secrets flow as Key Vault refs and
no credential ever lands in Terraform state.

## Files

| File                | Contents                                                        |
|---------------------|-----------------------------------------------------------------|
| `main.tf`           | `terraform` block (versions, `azurerm = 4.81.0`, `time`)        |
| `variables.tf`      | Location, resource group, image/app/scaling/ingress/health/env/secret objects, tags |
| `locals.tf`         | App / environment / identity names, `common_tags`               |
| `outputs.tf`        | App id, FQDN, environment id, identity ids                      |
| `container_app.tf`  | Identity, environment, role assignments, `time_sleep` guard, app |
| `README.Resources.md` | Per-resource inventory                                        |

## RBAC propagation guard

AAD role assignments propagate asynchronously; a first-deploy image pull or
secret resolve can fail before they land. `time_sleep.rbac_propagation`
(default `60s`) sits between the assignments and the app via `depends_on`.
Create-only: only `create_duration` is set (no `update_duration`), so the
60s wait runs once at creation — image-only/tag changes do not retrigger it.

## Usage

```hcl
module "app" {
  source                       = "./modules/ck-labs_az_container_app"
  location                     = "southafricanorth"
  resource_group_name          = "rg-ck-labs-dev"
  environment                  = "dev"
  log_analytics_workspace_id   = module.observability.workspace_id
  registry_login_server        = module.registry.login_server
  registry_id                  = module.registry.id
  key_vault_id                 = module.vault.id

  key_vault_secrets = {
    "riskshield-api-key" = module.vault.secret_ids["riskshield-api-key"]
  }

  secret_env = {
    "RiskShield__ApiKey" = "riskshield-api-key"
  }
}
```
