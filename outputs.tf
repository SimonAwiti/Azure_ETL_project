# outputs.tf
# This file defines the output values that will be displayed after Terraform applies the config.

output "resource_group_name" {
  description = "Name of the deployed Resource Group"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Name of the deployed Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "sql_server_fully_qualified_domain_name" {
  description = "Fully Qualified Domain Name of the SQL Server (will resolve privately via Private DNS Zone)"
  # Use the standard FQDN, which will resolve privately within the VNet due to the Private DNS Zone link.
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "datalake_gen2_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Data Lake Gen2 storage account (will resolve privately via Private DNS Zone)"
  # Use the standard blob endpoint, which will resolve privately within the VNet due to the Private DNS Zone link.
  value = azurerm_storage_account.datalake_gen2.primary_blob_host
}

output "iot_hub_hostname" {
  description = "Hostname of the IoT Hub"
  value       = azurerm_iothub.main.hostname
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation Key for Application Insights"
  sensitive   = true
  value       = azurerm_application_insights.main.instrumentation_key
}