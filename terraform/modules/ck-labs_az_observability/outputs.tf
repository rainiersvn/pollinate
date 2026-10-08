# Workspace handles the Phase 5 root module needs (id for the Container
# Apps environment, connection string for the API's telemetry config).

output "workspace_id" {
  description = "Log Analytics workspace id (Container Apps environment link)."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  description = "Log Analytics workspace name."
  value       = azurerm_log_analytics_workspace.this.name
}

output "app_insights_id" {
  description = "Application Insights id."
  value       = azurerm_application_insights.this.id
}

output "app_insights_name" {
  description = "Application Insights name."
  value       = azurerm_application_insights.this.name
}

output "connection_string" {
  description = "Application Insights connection string for the API."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
