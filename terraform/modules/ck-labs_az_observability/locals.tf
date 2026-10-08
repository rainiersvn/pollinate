# Shared names and tags for ck-labs observability.

locals {
  workspace_name    = "${var.name_prefix}-${var.environment}-law"
  app_insights_name = "${var.name_prefix}-${var.environment}-appi"

  common_tags = merge(
    {
      project     = "ck-labs"
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags,
  )
}
