# Shared names and tags for the ck-labs root module.

locals {
  resource_group_name = "rg-${var.name_prefix}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
    },
    var.tags,
  )
}
