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
  service_endpoints = ["Microsoft.Web", "Microsoft.Storage", "Microsoft.Sql"]
}

# DB Subnet (for Azure SQL DB Private Endpoint)
resource "azurerm_subnet" "db" {
  name                 = var.db_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.db_subnet_address_prefixes

  # No service endpoints needed here if using Private Endpoints, as traffic goes over private link
}

# Data Lake Subnet (for Azure Data Lake Gen2 Private Endpoint)
resource "azurerm_subnet" "datalake" {
  name                 = var.datalake_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.datalake_subnet_address_prefixes
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
    description                = "Allow HTTP for Function App HTTP Trigger"
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
    description                = "Allow HTTPS for Function App HTTP Trigger"
  }

  security_rule {
    name                       = "AllowIotHubEventHub"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureIoTHub" # Corrected Service Tag
    destination_address_prefix = "*"
    description                = "Allow traffic from IoT Hub's Event Hub endpoint"
  }

  security_rule {
    name                       = "AllowSqlOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.db.address_prefixes[0] # Allow outbound to DB Subnet
    description                = "Allow outbound to Azure SQL DB Private Endpoint"
  }

  security_rule {
    name                       = "AllowDataLakeOutbound"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp" # Or use "*" for all protocols if needed
    source_port_range          = "*"
    destination_port_range     = "443" # HTTPS for storage operations
    source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.datalake.address_prefixes[0] # Allow outbound to Data Lake Subnet
    description                = "Allow outbound to Data Lake Gen2 Private Endpoint"
  }
}

# NSG for DB Subnet - Primarily for Private Endpoint, very restrictive
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.db_subnet_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all inbound traffic by default, Private Endpoint will bypass NSG for SQL traffic"
  }
}

# NSG for Data Lake Subnet - Primarily for Private Endpoint, very restrictive
resource "azurerm_network_security_group" "datalake_nsg" {
  name                = "${var.datalake_subnet_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all inbound traffic by default, Private Endpoint will bypass NSG for storage traffic"
  }
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

resource "azurerm_subnet_network_security_group_association" "datalake_association" {
  subnet_id                 = azurerm_subnet.datalake.id
  network_security_group_id = azurerm_network_security_group.datalake_nsg.id
}

# --- Storage Account for Function App ---
# Azure Function Apps require a storage account for their operation.
resource "azurerm_storage_account" "function_app_storage" {
  name                     = var.function_app_storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"    # Locally Redundant Storage for cost-effectiveness
  min_tls_version          = "TLS1_2" # Enforce TLS 1.2 for security
}

# --- App Service Plan (for Function App) ---
resource "azurerm_service_plan" "function_app_plan" {
  name                = "${var.function_app_name}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "P1v2"
  os_type             = "Windows"
}

# --- Azure Function App (Windows) ---
# Changed resource type from azurerm_function_app to azurerm_windows_function_app
resource "azurerm_windows_function_app" "main" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.function_app_plan.id # Use service_plan_id for azurerm_windows_function_app
  storage_account_name       = azurerm_storage_account.function_app_storage.name
  storage_account_access_key = azurerm_storage_account.function_app_storage.primary_access_key
  virtual_network_subnet_id  = azurerm_subnet.app.id # VNet integration handled directly here

  site_config {
    vnet_route_all_enabled = true # Route all outbound traffic through the VNet
    # client_affinity_enabled is not typically set here for azurerm_windows_function_app
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "18" # Explicitly set Node.js version for Windows
    "WEBSITE_VNET_ROUTE_ALL"                = "1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    # Use the standard FQDN for SQL Server; Private DNS Zone will handle private resolution
    "SQL_CONNECTION_STRING" = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Authentication=Active Directory Integrated;" # Managed Identity
    # Use the standard DFS endpoint for Data Lake Gen2; Private DNS Zone will handle private resolution
    "DATALAKE_ACCOUNT_NAME" = azurerm_storage_account.datalake_gen2.name
    "DATALAKE_DFS_ENDPOINT" = azurerm_storage_account.datalake_gen2.primary_dfs_endpoint
  }
  identity {
    type = "SystemAssigned" # Enable Managed Identity for the Function App
  }
}

# Removed azurerm_app_service_virtual_network_swift_connection as it's now handled by virtual_network_subnet_id in azurerm_windows_function_app


# --- Azure IoT Hub ---
resource "azurerm_iothub" "main" {
  name                = var.iot_hub_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = "S1"
    capacity = 1
  }

  tags = {
    "Purpose" = "IoT Data Ingestion"
  }
}

# IoT Hub Consumer Group for Azure Function
resource "azurerm_iothub_consumer_group" "function_app_consumer_group" {
  name                   = var.iot_hub_consumer_group_name
  iothub_name            = azurerm_iothub.main.name
  eventhub_endpoint_name = "events" # Built-in Event Hub endpoint for telemetry
  resource_group_name    = azurerm_resource_group.main.name
}


# --- Azure SQL Server ---
resource "azurerm_mssql_server" "main" {
  name                          = var.sql_server_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false # Disable public access, rely on Private Endpoint
}

# --- Azure SQL Database ---
resource "azurerm_mssql_database" "main" {
  name        = var.sql_database_name
  server_id   = azurerm_mssql_server.main.id
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name    = "S0"
  max_size_gb = 2
}

# --- Private Endpoint for Azure SQL Database ---
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "${azurerm_mssql_server.main.name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.db.id

  private_service_connection {
    name                           = "${azurerm_mssql_server.main.name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }
}

# --- Private DNS Zone for Azure SQL Database ---
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_vnet_link" {
  name                  = "sql-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}


# --- Data Lake Gen2 Storage Account ---
resource "azurerm_storage_account" "datalake_gen2" {
  name                          = var.datalake_storage_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  account_tier                  = "Standard"
  account_replication_type      = "GRS"
  is_hns_enabled                = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = false # Disable public access, rely on Private Endpoint
}

# --- Private Endpoint for Data Lake Gen2 Storage Account (Blob) ---
resource "azurerm_private_endpoint" "datalake_blob_private_endpoint" {
  name                = "${azurerm_storage_account.datalake_gen2.name}-blob-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.datalake.id

  private_service_connection {
    name                           = "${azurerm_storage_account.datalake_gen2.name}-blob-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.datalake_gen2.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.datalake_blob_dns_zone.id]
  }
}

# --- Private Endpoint for Data Lake Gen2 Storage Account (DFS - for ABFS driver) ---
resource "azurerm_private_endpoint" "datalake_dfs_private_endpoint" {
  name                = "${azurerm_storage_account.datalake_gen2.name}-dfs-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.datalake.id

  private_service_connection {
    name                           = "${azurerm_storage_account.datalake_gen2.name}-dfs-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.datalake_gen2.id
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.datalake_dfs_dns_zone.id]
  }
}


# --- Private DNS Zone for Data Lake Gen2 Storage Account (Blob) ---
resource "azurerm_private_dns_zone" "datalake_blob_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "datalake_blob_dns_vnet_link" {
  name                  = "datalake-blob-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.datalake_blob_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

# --- Private DNS Zone for Data Lake Gen2 Storage Account (DFS) ---
resource "azurerm_private_dns_zone" "datalake_dfs_dns_zone" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "datalake_dfs_dns_vnet_link" {
  name                  = "datalake-dfs-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.datalake_dfs_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}


# --- Monitoring and Alerting ---

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights for Function App
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
}

# Diagnostic Settings to send logs/metrics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "function_app_diag" {
  name                       = "function-app-diag-settings"
  target_resource_id         = azurerm_windows_function_app.main.id # Updated resource reference
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Reverted to 'log' and 'metric' blocks
  log {
    category = "FunctionAppLogs"
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_server_diag" {
  name                       = "sql-server-diag-settings"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Reverted to 'log' and 'metric' blocks
  log {
    category = "SQLInsights"
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "iot_hub_diag" {
  name                       = "iot-hub-diag-settings"
  target_resource_id         = azurerm_iothub.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Reverted to 'log' and 'metric' blocks
  log {
    category = "Connections"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  log {
    category = "DeviceTelemetry"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  log {
    category = "C2DCommands"
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "datalake_diag" {
  name                       = "datalake-diag-settings"
  target_resource_id         = azurerm_storage_account.datalake_gen2.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Reverted to 'log' and 'metric' blocks (only metrics were configured previously)
  metric {
    category = "Transaction"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  metric {
    category = "Capacity"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

# --- Action Group for Alerts ---
resource "azurerm_monitor_action_group" "main" {
  name                = var.action_group_name
  resource_group_name = azurerm_resource_group.main.name
  short_name          = var.action_group_short_name # Ensure this variable is 1-12 characters in variables.tf

  email_receiver {
    name          = "admin_email"
    email_address = var.admin_email_for_alerts
  }
}

# --- Metric Alerts ---

# Function App: HTTP 5xx Errors Alert
resource "azurerm_monitor_metric_alert" "function_app_http_errors_alert" {
  name                     = "func-app-http-5xx-errors-alert"
  resource_group_name      = azurerm_resource_group.main.name
  scopes                   = [azurerm_windows_function_app.main.id] # Updated resource reference
  description              = "Alert when Function App experiences high rate of HTTP 5xx errors."
  target_resource_type     = "Microsoft.Web/sites"
  target_resource_location = azurerm_resource_group.main.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT5M"

  criteria {
    metric_namespace = "microsoft.web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
    dimension {
      name     = "Host"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# SQL Database: DTU Usage Alert
resource "azurerm_monitor_metric_alert" "sql_db_dtu_usage_alert" {
  name                     = "sql-db-dtu-usage-alert"
  resource_group_name      = azurerm_resource_group.main.name
  scopes                   = [azurerm_mssql_database.main.id]
  description              = "Alert when SQL Database DTU usage is high."
  target_resource_type     = "Microsoft.Sql/servers/databases"
  target_resource_location = azurerm_resource_group.main.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT15M"

  criteria {
    metric_namespace = "microsoft.sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# IoT Hub: Telemetry Message Errors Alert
resource "azurerm_monitor_metric_alert" "iot_hub_telemetry_errors_alert" {
  name                     = "iot-hub-telemetry-errors-alert"
  resource_group_name      = azurerm_resource_group.main.name
  scopes                   = [azurerm_iothub.main.id]
  description              = "Alert when IoT Hub telemetry messages have errors."
  target_resource_type     = "Microsoft.Devices/IotHubs"
  target_resource_location = azurerm_resource_group.main.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT5M"

  criteria {
    metric_namespace = "microsoft.devices/iothubs"
    metric_name      = "Errors"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Data Lake Gen2: Transaction Errors Alert
resource "azurerm_monitor_metric_alert" "datalake_transaction_errors_alert" {
  name                     = "datalake-transaction-errors-alert"
  resource_group_name      = azurerm_resource_group.main.name
  scopes                   = [azurerm_storage_account.datalake_gen2.id]
  description              = "Alert when Data Lake Gen2 experiences transaction errors."
  target_resource_type     = "Microsoft.Storage/storageAccounts"
  target_resource_location = azurerm_resource_group.main.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT5M"

  criteria {
    metric_namespace = "microsoft.storage/storageaccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
    dimension {
      name     = "ResponseType"
      operator = "Include"
      values   = ["ServerOtherError", "ClientOtherError"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}