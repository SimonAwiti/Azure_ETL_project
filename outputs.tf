output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  value = {
    analytics = azurerm_subnet.analytics.id
    app       = azurerm_subnet.app.id
    storage   = azurerm_subnet.storage.id
  }
}
output "storage_subnet_name" {
  value = azurerm_subnet.storage.name
}