# outputs.tf
# This file defines the output values that will be displayed after Terraform applies the configuration.

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
  value       = azurerm_function_app.main.default_hostname
}

output "sql_server_fully_qualified_domain_name" {
  description = "Fully Qualified Domain Name of the SQL Server"
  value       = azurerm_sql_server.main.fully_qualified_domain_name
}

output "datalake_gen2_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Data Lake Gen2 storage account"
  value       = azurerm_storage_account.datalake_gen2.primary_blob_endpoint
}

output "synapse_workspace_web_url" {
  description = "Web URL for the Synapse Workspace"
  value       = azurerm_synapse_workspace.main.web_url
}
