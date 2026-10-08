# ck-labs_az_key_vault — resources

| Resource                     | Type                      | Purpose                                            |
|------------------------------|---------------------------|----------------------------------------------------|
| `data.azurerm_client_config.current` | data source        | Ambient tenant id (root passes no tenant)          |
| `azurerm_key_vault.this`      | `azurerm_key_vault`       | RBAC-only secret store                             |
| `azurerm_key_vault_secret.this` | `azurerm_key_vault_secret` | Managed secrets, one per `var.secrets` entry    |
