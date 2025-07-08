output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.main.location
}

output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "storage_account_primary_access_key" {
  value     = azurerm_storage_account.datalake.primary_access_key
  sensitive = true
}

output "function_app_name" {
  value = azurerm_linux_function_app.main.name
}

output "subnet_ids" {
  value = {
    analytics = azurerm_subnet.analytics.id
    app       = azurerm_subnet.app.id
    storage   = azurerm_subnet.storage.id
  }
}