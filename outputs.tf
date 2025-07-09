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
  description = "Fully Qualified Domain Name of the SQL Server (via Private Endpoint DNS)"
  # For the FQDN via Private Endpoint, typically the private_ip_address combined with the private DNS zone or the fqdns attribute from the private service connection if available.
  # If 'fqdns' still gives an error, use the service's original FQDN and rely on the Private DNS Zone Link for resolution within the VNet.
  # As per the error, 'fqdns' is not directly available on 'private_service_connection'.
  # For now, let's output the private IP and assume private DNS will handle resolution.
  # A more robust solution might involve creating azurerm_private_dns_a_record explicitly.
  value = azurerm_private_endpoint.sql_private_endpoint.private_ip_address # Using private IP as a workaround if fqdns is not exported
}

output "datalake_gen2_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Data Lake Gen2 storage account (via Private Endpoint DNS)"
  # Similar to SQL, if 'fqdns' is not available, we use the private IP and construct the endpoint.
  value = "https://${azurerm_private_endpoint.datalake_blob_private_endpoint.private_ip_address}.blob.core.windows.net/"
}

output "iot_hub_hostname" {
  description = "Hostname of the IoT Hub"
  value       = azurerm_iothub.main.hostname # Corrected resource type
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