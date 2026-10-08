# ck-labs_az_container_registry

Azure Container Registry holding the ck-labs API image. Pull is managed-identity
only: the admin account stays disabled and `ck-labs_az_container_app` grants its
identity `AcrPull` on this registry.

## Files

| File                | Contents                                              |
|---------------------|-------------------------------------------------------|
| `main.tf`           | `terraform` block (versions, `azurerm = 4.81.0`)       |
| `variables.tf`      | Location, resource group, one `registry` object, tags |
| `locals.tf`         | Alphanumeric registry name, `common_tags`             |
| `outputs.tf`        | Registry id, name, login server                       |
| `registry.tf`       | `azurerm_container_registry`                          |
| `README.Resources.md` | Per-resource inventory                              |

## Usage

```hcl
module "registry" {
  source              = "./modules/ck-labs_az_container_registry"
  location            = "southafricanorth"
  resource_group_name = "rg-ck-labs-dev"
  environment         = "dev"

  registry = {
    sku = "Basic"
  }
}
```
