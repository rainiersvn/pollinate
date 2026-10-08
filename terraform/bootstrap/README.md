# ck-labs Terraform bootstrap

Run-once root that creates the Azure Storage the FinSure platform uses for
remote Terraform state. Backend here is **local** (default `terraform.tfstate`,
git-ignored): this root must exist before anything else has remote state to store.

Creates (KISS — one LRS account, isolation by container):

- Resource group `rg-ck-labs-tfstate`
- Storage account `cklabstfstate<storage_suffix>` (TLS 1.2, no public blobs)
- Private containers `tfstate-dev` and `tfstate-prod`

## Exact commands

```powershell
az login
cd Pollinate/terraform/bootstrap

terraform init
terraform fmt -check
terraform validate
terraform plan -out bootstrap.tfplan
terraform apply bootstrap.tfplan   # run once per subscription
```

If `cklabstfstatefin01` is taken (storage names are global), re-run plan/apply
with `-var storage_suffix=<unique>` (2–8 lowercase alphanumeric chars).

## Wiring Phase 5

After apply, read the backend values from outputs:

```powershell
terraform output storage_account_name
terraform output resource_group_name
```

and use them in the root module backend, e.g. for dev:

```hcl
backend "azurerm" {
  resource_group_name  = "<resource_group_name output>"
  storage_account_name = "<storage_account_name output>"
  container_name       = "tfstate-dev"
  key                  = "dev.terraform.tfstate"
}
```

(prod identical, with `tfstate-prod` / `prod.terraform.tfstate`.)

## Never destroy

Do not `terraform destroy` this root while any environment stores state here —
that orphans dev/prod state. Tear down environments first, then bootstrap last.
Both the resource group and the storage account carry
`lifecycle { prevent_destroy = true }`, so a destroy (or an apply that would
replace them) fails until that guard is deliberately removed.

Known gaps (documented, not mitigated): the storage account carries no `tags`
and `public_network_access_enabled` is left at the provider default (no network
lockdown). State protection comes from private containers, no public blobs,
and TLS 1.2 — wire tags + network rules before handling real PII.
