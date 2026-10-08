# Shared names and tags for the ck-labs container registry.

locals {
  # Registry names allow alphanumerics only: "ck-labs" -> "cklabs".
  registry_name = coalesce(
    var.registry.name,
    "${lower(replace(var.name_prefix, "-", ""))}${var.environment}acr",
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
