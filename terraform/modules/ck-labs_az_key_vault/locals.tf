# Shared names and tags for the ck-labs key vault.

locals {
  vault_name = coalesce(
    var.vault.name,
    "${var.name_prefix}-${var.environment}-kv",
  )

  common_tags = merge(
    {
      project     = "ck-labs"
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags,
  )
}
