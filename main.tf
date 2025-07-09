# Reference existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = "australiacentral"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Subnets
resource "azurerm_subnet" "analytics" {
  name                 = var.analytics_subnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.analytics_subnet_address
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
}

resource "azurerm_subnet" "app" {
  name                 = var.app_subnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.app_subnet_address
  service_endpoints    = ["Microsoft.Web", "Microsoft.Storage"]
}

resource "azurerm_subnet" "storage" {
  name                 = var.storage_subnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.storage_subnet_address
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "databricks-del"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "analytics_nsg" {
  name                = "analytics-nsg-aus-central"
  location            = "australiacentral"
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSynapse"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg-aus-central"
  location            = "australiacentral"
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "storage_nsg" {
  name                = "storage-nsg-aus-central"
  location            = "australiacentral"
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowStorageService"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "analytics" {
  subnet_id                 = azurerm_subnet.analytics.id
  network_security_group_id = azurerm_network_security_group.analytics_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "storage" {
  subnet_id                 = azurerm_subnet.storage.id
  network_security_group_id = azurerm_network_security_group.storage_nsg.id
}

# Storage Account with Australia Central redundancy
resource "azurerm_storage_account" "datalake" {
  name                     = "${lower(replace(var.storage_account_name, "/[^a-z0-9]/", ""))}aus"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = "australiacentral"
  account_tier             = "Standard"
  account_replication_type = "ZRS" # Zone-redundant for Australia Central
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.storage.id,
      azurerm_subnet.analytics.id,
      azurerm_subnet.app.id
    ]
    ip_rules = [] # Add your CI/CD pipeline IP if needed
  }
}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "curated" {
  name                  = "curated"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

# Function App with Australia Central configuration
resource "azurerm_service_plan" "function" {
  name                = "func-plan-aus-central"
  location            = "australiacentral"
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "EP1" # Elastic Premium for better quota availability
}

resource "azurerm_linux_function_app" "main" {
  name                = "${var.function_app_name}-aus-central"
  location            = "australiacentral"
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.function.id

  storage_account_name       = azurerm_storage_account.datalake.name
  storage_account_access_key = azurerm_storage_account.datalake.primary_access_key

  site_config {
    application_stack {
      node_version = "18"
    }
    vnet_route_all_enabled = true
    ip_restriction {
      virtual_network_subnet_id = azurerm_subnet.app.id
    }
  }

  virtual_network_subnet_id = azurerm_subnet.app.id

  depends_on = [
    azurerm_subnet_network_security_group_association.app
  ]
}