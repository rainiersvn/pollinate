# Log Analytics workspace + workspace-backed Application Insights for
# ck-labs. The Container Apps environment sends console logs here.

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.workspace.sku
  retention_in_days   = var.workspace.retention_days
  daily_quota_gb      = var.workspace.daily_quota_gb
  tags                = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
  retention_in_days   = var.insights.retention_days
  sampling_percentage = var.insights.sampling
  tags                = local.common_tags
}
