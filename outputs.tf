# outputs.tf
output "resource_group_id" {
  description = "The ID of the resource group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.main.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Azure Function App."
  value       = azurerm_windows_function_app.main.default_hostname # Corrected resource reference
}

output "sql_server_fully_qualified_domain_name" {
  description = "The fully qualified domain name of the Azure SQL Server."
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "iot_hub_hostname" {
  description = "The hostname of the Azure IoT Hub."
  value       = azurerm_iothub.main.hostname
}

output "datalake_gen2_primary_dfs_endpoint" {
  description = "The primary DFS endpoint for the Data Lake Gen2 Storage Account."
  value       = azurerm_storage_account.datalake_gen2.primary_dfs_endpoint
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  description = "The Instrumentation Key for Application Insights."
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}