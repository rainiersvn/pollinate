# prod tfvars: delete lock on.
name_prefix = "ck-labs"
environment = "prod"
location    = "southafricanorth"
project     = "ck-labs"
lock_type   = "CanNotDelete"
# Names only (no values): container env -> Key Vault secret-block name.
# The secret value arrives via pipeline -var/TF_VAR_ `secrets` (see README Deploy §2).
secret_env = {
  "RiskShield__ApiKey" = "riskshield-api-key"
}
