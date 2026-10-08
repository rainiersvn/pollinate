# ck-labs_az_container_app — resources

| Resource                                          | Type                             | Purpose                                              |
|---------------------------------------------------|----------------------------------|------------------------------------------------------|
| `azurerm_user_assigned_identity.this`              | `azurerm_user_assigned_identity`  | App identity (registry pull, secret resolve)         |
| `azurerm_container_app_environment.this`           | `azurerm_container_app_environment` | Consumption environment, logs to workspace        |
| `azurerm_role_assignment.acr_pull`                 | `azurerm_role_assignment`         | `AcrPull` on the registry for the app identity       |
| `azurerm_role_assignment.key_vault_secrets_user`   | `azurerm_role_assignment`         | `Key Vault Secrets User` on the vault                |
| `time_sleep.rbac_propagation`                      | `time_sleep`                      | RBAC propagation guard before first pull             |
| `azurerm_container_app.this`                       | `azurerm_container_app`           | ck-labs API (MI registry, Key Vault refs, probes)    |
