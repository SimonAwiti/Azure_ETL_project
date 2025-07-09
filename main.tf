# main.tf
# This file contains the main resource definitions for the Azure architecture.

# --- Resource Group ---
# A logical container for all your Azure resources.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# --- Virtual Network (VNet) ---
# The fundamental building block for your private network in Azure.
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# --- Subnets ---
# Divide the VNet into smaller, isolated segments.

# Application Subnet (for Azure Function)
resource "azurerm_subnet" "app" {
  name                 = var.app_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.app_subnet_address_prefixes

  # Required for Function Apps to integrate with a VNet
  service_endpoints = ["Microsoft.Web"]
}

# DB Subnet (for Azure SQL DB)
resource "azurerm_subnet" "db" {
  name                 = var.db_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.db_subnet_address_prefixes

  # Required for SQL Database Private Endpoint
  service_endpoints = ["Microsoft.Sql"]
}

# Analytics Subnet (for Azure Synapse Analytics)
resource "azurerm_subnet" "analytics" {
  name                 = var.analytics_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.analytics_subnet_address_prefixes

  # Required for Synapse Workspace managed VNet integration
  # and for private endpoints to Synapse resources.
  # Note: Synapse often deploys its own managed VNet, but if you want
  # to integrate it with an existing VNet, service endpoints or private
  # endpoints are used.
  service_endpoints = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.AzureActiveDirectory"]
  # Delegating the subnet to Synapse can be done if using managed VNet for Synapse
  # delegation {
  #   name = "Microsoft.Synapse/workspaces"
  #   service_delegation {
  #     name = "Microsoft.Synapse/workspaces"
  #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  #   }
  # }
}

# --- Network Security Groups (NSGs) ---
# Filter network traffic to and from Azure resources in an Azure virtual network.

# NSG for Application Subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.app_subnet_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  # Add more specific rules as per your security requirements (e.g., allow traffic from IoT Hub, user-facing apps)
}

# NSG for DB Subnet
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.db_subnet_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSQLFromAppSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"                                 # Default SQL Server port
    source_address_prefix      = azurerm_subnet.app.address_prefixes[0] # Allow from App Subnet
    destination_address_prefix = "*"
  }
  # Add more specific rules (e.g., allow from Synapse, deny all other inbound)
}

# NSG for Analytics Subnet
resource "azurerm_network_security_group" "analytics_nsg" {
  name                = "${var.analytics_subnet_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSynapseTraffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork" # Allow traffic from within the VNet
    destination_address_prefix = "*"
  }
  # Add more specific rules (e.g., allow from Data Lake, Power BI)
}

# --- Subnet NSG Associations ---
# Link the NSGs to their respective subnets.
resource "azurerm_subnet_network_security_group_association" "app_association" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_association" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "analytics_association" {
  subnet_id                 = azurerm_subnet.analytics.id
  network_security_group_id = azurerm_network_security_group.analytics_nsg.id
}

# --- Storage Account for Function App ---
# Azure Function Apps require a storage account for their operation.
resource "azurerm_storage_account" "function_app_storage" {
  name                     = var.function_app_storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage for cost-effectiveness
}

# --- App Service Plan (for Function App) ---
# Defines the underlying compute resources for your Function App.
resource "azurerm_app_service_plan" "function_app_plan" {
  name                = "${var.function_app_name}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp" # Specify FunctionApp kind for Function Apps
  sku {
    tier = "Consumption" # Consumption plan for serverless functions
    size = "Y1"
  }
}

# --- Azure Function App ---
# The serverless compute service for event-driven applications.
resource "azurerm_function_app" "main" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.function_app_plan.id
  storage_account_name       = azurerm_storage_account.function_app_storage.name
  storage_account_access_key = azurerm_storage_account.function_app_storage.primary_access_key
  os_type                    = "Linux" # Or "Windows" based on your preference
  version                    = "~4"    # Function App runtime version (e.g., ~4 for .NET 6/7, Node 16/18, Python 3.9/3.10)

  # Enable VNet integration for the Function App
  virtual_network_subnet_id = azurerm_subnet.app.id

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "node" # Example: "dotnet", "node", "python", "java", "powershell"
    "WEBSITE_VNET_ROUTE_ALL"         = "1"    # Route all outbound traffic through the VNet
    "APPINSIGHTS_INSTRUMENTATIONKEY" = ""     # Add Application Insights key if needed
  }
  # Add more settings as required by your function app
}

# --- Azure SQL Server ---
# The logical server that hosts your SQL databases.
resource "azurerm_sql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0" # SQL Server version
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2" # Recommended for security

  # Allow Azure services to access the server (e.g., Function App, Synapse)
  # This is a broad rule; consider more specific private endpoints for production.
  public_network_access_enabled = true # Set to false and use private endpoints for production
}

# --- Azure SQL Database ---
# The actual database instance within the SQL Server.
resource "azurerm_sql_database" "main" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_id           = azurerm_sql_server.main.id
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  sku_name            = "Standard_S0" # Basic SKU for demonstration
  max_size_gb         = 2
}

# --- Data Lake Gen2 Storage Account ---
# A storage account configured for hierarchical namespace, suitable for analytics.
resource "azurerm_storage_account" "datalake_gen2" {
  name                     = var.datalake_storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-Redundant Storage for higher durability
  is_hns_enabled           = true  # Enable hierarchical namespace for Data Lake Gen2
}
