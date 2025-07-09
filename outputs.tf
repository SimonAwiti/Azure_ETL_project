output "resource_group_name" {
  description = "Name of the existing resource group"
  value       = data.azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = data.azurerm_resource_group.main.location
}

output "virtual_network_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.datalake.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.datalake.id
}

output "storage_account_primary_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.datalake.primary_access_key
  sensitive   = true
}

output "function_app_name" {
  description = "Name of the function app"
  value       = azurerm_linux_function_app.main.name
}

output "function_app_hostname" {
  description = "Hostname of the function app"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_principal_id" {
  description = "Managed identity principal ID"
  value       = azurerm_linux_function_app.main.identity[0].principal_id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    analytics = azurerm_subnet.analytics.id
    app       = azurerm_subnet.app.id
    storage   = azurerm_subnet.storage.id
  }
}