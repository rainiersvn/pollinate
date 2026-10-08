# dev tfvars: no lock, child defaults everywhere else.
name_prefix = "ck-labs"
environment = "dev"
location    = "southafricanorth"
project     = "ck-labs"
lock_type   = ""
# Names only (no values): container env -> Key Vault secret-block name.
# The secret value arrives via pipeline -var/TF_VAR_ `secrets` (see README Deploy §2).
secret_env = {
  "RiskShield__ApiKey" = "riskshield-api-key"
}
