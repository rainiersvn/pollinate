# Shared names and tags for the ck-labs container app.

locals {
  app_name      = "${var.name_prefix}-${var.environment}-app"
  env_name      = "${var.name_prefix}-${var.environment}-cae"
  identity_name = "${var.name_prefix}-${var.environment}-id"

  common_tags = merge(
    {
      project     = "ck-labs"
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags,
  )
}
