# ck-labs root module

One resource group plus the four Phase 4 child modules, wired together:

- `observability` first (Log Analytics + App Insights)
- `registry` login server + id into `container_app` (image prefix, AcrPull scope)
- `vault` id + `secret_ids` into `container_app` (Secrets User scope, secret refs)
- `container_app` carries `depends_on = [module.observability]`; the 60s RBAC
  propagation guard (`time_sleep.rbac_propagation`) already lives in the child

## Files

| File                       | Contents                                                         |
|----------------------------|------------------------------------------------------------------|
| `main.tf`                  | `terraform` block (versions, `azurerm` backend), provider, RG, lock, modules |
| `variables.tf`             | Naming, tags, lock, child pass-throughs                  |
| `locals.tf`                | `rg-<prefix>-<env>` name, `Environment`/`Project` tags          |
| `outputs.tf`               | RG name, app FQDN, registry server, vault URI                    |
| `environments/dev.tfvars`  | dev: no lock                                             |
| `environments/prod.tfvars` | prod: `CanNotDelete` lock                                |

Provider blocks live only here; child modules declare `required_providers`
and inherit this configuration.

## Backend wiring

The storage account name carries a globally-unique suffix, so it is never
hardcoded. Apply the bootstrap root once, then read its outputs:

```powershell
cd bootstrap
terraform output resource_group_name    # -> tfStateResourceGroup
terraform output storage_account_name   # -> tfStateStorageAccount
cd ..
```

Init per environment with those values:

```powershell
terraform init -reconfigure `
  -backend-config="resource_group_name=<tfStateResourceGroup>" `
  -backend-config="storage_account_name=<tfStateStorageAccount>" `
  -backend-config="container_name=tfstate-dev" `
  -backend-config="key=dev.terraform.tfstate"
```

(prod identical, with `tfstate-prod` / `prod.terraform.tfstate`.)

## Bootstrap output → variable group wiring

Copy each bootstrap/root output into the matching variable-group variable.
Secret *values* never go here: only names and non-secret coordinates.

| Source (terraform output) | Variable group variable | Used by |
|---|---|---|
| `bootstrap: resource_group_name` | `tfStateResourceGroup` | `terraform init -backend-config` (both envs) |
| `bootstrap: storage_account_name` | `tfStateStorageAccount` | `terraform init -backend-config` (both envs) |
| `root: resource_group_name` (`rg-ck-labs-<env>`) | `appResourceGroup` | Deploy verify `az containerapp show -g` |
| `root: app_fqdn` | `appFqdn` | Smoke `https://$(appFqdn)/health/*` |
| `module.container_app.name` (via `root: app_name`) | `containerAppName` | Deploy verify `--name` |
| `root: registry_login_server` (host part) | `acrName` | Build `az acr login --name`, image prefix |
| `root: vault_uri` (vault name part) | `keyVaultName` | Secret triage (`az keyvault secret show`) |
| Key Vault secret `riskshield-api-key` (value, never committed) | `riskShieldApiKey` (secret, via Key Vault–linked group) | Infra plan `-var="secrets={...}"` → vault secret + Container App ref |

`vg-ck-labs-dev` and `vg-ck-labs-prod` carry the same keys with per-env
values. Key Vault–linked groups resolve secret values at queue time; the
pipeline itself only references `$(...)` names.

## Exact commands

```powershell
cd Pollinate/terraform

terraform fmt -check -recursive
terraform init -backend=false   # offline validate; no backend needed
terraform validate

# Per environment (after backend init above):
# `secrets` carries only the secret NAME->value map and never lives in tfvars:
# pass it via -var (from a Key Vault-linked variable / env) as the pipeline does.
# tfvars carry only the secret_env NAME->secret-block mapping (see First deploy).
terraform plan -var-file=environments/dev.tfvars -out dev.tfplan -var="image={ name = \"finsure-risk-scoring\", tag = \"local\" }" -var='secrets={"riskshield-api-key"="<from Key Vault / pipeline secret>"}'
terraform plan -var-file=environments/prod.tfvars -out prod.tfplan -var="image={ name = \"finsure-risk-scoring\", tag = \"local\" }" -var='secrets={"riskshield-api-key"="<from Key Vault / pipeline secret>"}'
```

## First deploy (RiskShield key wiring)

Without this the API crash-loops (`RiskShield__ApiKey` is `Required` +
`ValidateOnStart`) and the Container App renders no `secret` block
(`for_each` over an empty `secret_ids` map).

1. `environments/{dev,prod}.tfvars` already carry the name-only mapping
   `secret_env = { "RiskShield__ApiKey" = "riskshield-api-key" }`.
2. Supply the value out-of-band per the root README Deploy §2:
   `riskShieldApiKey` (Key Vault–linked variable group) →
   `-var="secrets={ \"riskshield-api-key\" = \"$RISKSHIELD_API_KEY\" }"`.
   The root module forwards `module.vault.secret_ids` into
   `container_app.key_vault_secrets`, so the `secret` block + env ref appear
   on the first apply that receives a non-empty `secrets` map.

## Notes

- `lock_type = ""` disables the `azurerm_management_lock` (dev);
  `"CanNotDelete"` (prod) or `"ReadOnly"` enables it. The lock scopes to the
  environment resource group (`rg-ck-labs-<env>`): with `CanNotDelete` even a
  `terraform destroy` of the RG contents is blocked until the lock is removed,
  so prod teardown is a deliberate two-step (remove lock, then destroy). Dev
  stays lock-free for fast iteration.
- No IP allow-list knob exists: no child module takes one, so there is
  nothing to set in tfvars. Adding network hardening later means adding a
  module input (e.g. vault network ACLs). No root reshaping required.
- Never put secret values in tfvars. Pass `secrets` via pipeline-managed
  `-var` / `TF_VAR_` values instead. `terraform plan` renders secret values
  as `(sensitive value)`; if a value ever leaks into a tfvars or state diff,
  rotate it in Key Vault immediately.
- Version pins: every `terraform` block requires `>= 1.3.6`.
  `terraform/.terraform-version` pins the local dev CLI (`1.3.6`) while
  `pipelines/azure-pipelines.yml` (`tfVersion: 1.9.8`) pins CI. Both satisfy
  the constraint, so the `.terraform-version` file is intentionally left at
  `1.3.6`. Do not bump it to match CI without re-running `fmt` + `validate`
  on both roots first.
