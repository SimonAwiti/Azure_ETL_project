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
    source_address_prefix      = "AzureEventHub" # Allow traffic from Azure Event Hubs (used by IoT Hub)
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

  security_rule {
    name                       = "AllowAzurePlatform"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzurePlatformDNS" # Needed for Private Endpoint DNS resolution
    destination_address_prefix = "*"
    description                = "Allow Azure platform traffic for Private Endpoint"
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

  security_rule {
    name                       = "AllowAzurePlatform"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzurePlatformDNS" # Needed for Private Endpoint DNS resolution
    destination_address_prefix = "*"
    description                = "Allow Azure platform traffic for Private Endpoint"
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
  sku_name            = "Y1"    # Consumption plan SKU for cost optimization
  os_type             = "Linux" # Must match the Function App OS type
}

# --- Azure Function App ---
resource "azurerm_linux_function_app" "main" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.function_app_plan.id
  storage_account_name       = azurerm_storage_account.function_app_storage.name
  storage_account_access_key = azurerm_storage_account.function_app_storage.primary_access_key

  site_config {
    vnet_route_all_enabled   = true # Route all outbound traffic through the VNet
    application_insights_key = azurerm_application_insights.main.instrumentation_key
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "node" # Example: "dotnet", "node", "python", "java", "powershell"
    "WEBSITE_VNET_ROUTE_ALL"                = "1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    # For SQL DB access, consider Managed Identity instead of connection string directly in app settings
    "SQL_CONNECTION_STRING" = "Server=tcp:${azurerm_private_endpoint.sql_private_endpoint.private_service_connection[0].fqdns[0]},1433;Initial Catalog=${azurerm_mssql_database.main.name};Authentication=Active Directory Integrated;" # Example with Managed Identity
    "DATALAKE_ACCOUNT_NAME" = azurerm_storage_account.datalake_gen2.name
    # For Data Lake access, use Managed Identity.
  }
  identity {
    type = "SystemAssigned" # Enable Managed Identity for the Function App
  }
}

# Resource to link the Function App to the subnet
resource "azurerm_app_service_virtual_network_swift_connection" "function_app_vnet_integration" {
  app_service_id = azurerm_linux_function_app.main.id
  subnet_id      = azurerm_subnet.app.id
}

# --- Azure IoT Hub ---
resource "azurerm_iot_hub" "main" {
  name                = var.iot_hub_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = "B1" # Standard tier for production, B1 (Basic) for dev/test to optimize cost
    capacity = 1    # Number of units, adjust based on expected message volume
  }

  tags = {
    "Purpose" = "IoT Data Ingestion"
  }
}

# IoT Hub Consumer Group for Azure Function
resource "azurerm_iot_hub_consumer_group" "function_app_consumer_group" {
  name                   = var.iot_hub_consumer_group_name
  iot_hub_name           = azurerm_iot_hub.main.name
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
  minimum_tls_version           = "1.2" # Enforce TLS 1.2 for security
  public_network_access_enabled = false # Disable public access, rely on Private Endpoint
}

# --- Azure SQL Database ---
resource "azurerm_mssql_database" "main" {
  name        = var.sql_database_name
  server_id   = azurerm_mssql_server.main.id
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name    = "S0" # Cost-effective starting point, scale as needed
  max_size_gb = 2
}

# --- Private Endpoint for Azure SQL Database ---
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "${azurerm_mssql_server.main.name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.db.id # Connect to the DB subnet

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
  account_replication_type      = "LRS" # Geo-Redundant Storage for higher durability,  LRS/ZRS for cost
  is_hns_enabled                = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = false
}

# --- Private Endpoint for Data Lake Gen2 Storage Account (Blob) ---
resource "azurerm_private_endpoint" "datalake_blob_private_endpoint" {
  name                = "${azurerm_storage_account.datalake_gen2.name}-blob-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.datalake.id # Connect to the Data Lake subnet

  private_service_connection {
    name                           = "${azurerm_storage_account.datalake_gen2.name}-blob-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.datalake_gen2.id
    subresource_names              = ["blob"] # For blob (Data Lake Gen2) access
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
  subnet_id           = azurerm_subnet.datalake.id # Connect to the Data Lake subnet

  private_service_connection {
    name                           = "${azurerm_storage_account.datalake_gen2.name}-dfs-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.datalake_gen2.id
    subresource_names              = ["dfs"] # For DFS (ABFS) access
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

# Log Analytics Workspace (retention is configured here, not in diagnostic settings)
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018" # Cost-optimized SKU for Log Analytics
  retention_in_days   = 30          # Retain logs for 30 days, adjust for cost vs. compliance
}

# Application Insights for Function App
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web" # Or "other" depending on specific use case
  workspace_id        = azurerm_log_analytics_workspace.main.id
}

# Diagnostic Settings to send logs/metrics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "function_app_diag" {
  name                       = "function-app-diag-settings"
  target_resource_id         = azurerm_linux_function_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "FunctionAppLogs" # Or other relevant categories
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_server_diag" {
  name                       = "sql-server-diag-settings"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "SQLSecurityAudit"
    enabled  = true
  }
  log {
    category = "AutomaticTuning"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "iot_hub_diag" {
  name                       = "iot-hub-diag-settings"
  target_resource_id         = azurerm_iot_hub.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "Connections"
    enabled  = true
  }
  log {
    category = "DeviceTelemetry"
    enabled  = true
  }
  log {
    category = "C2DCommands" # Cloud to Device Commands
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "datalake_diag" {
  name                       = "datalake-diag-settings"
  target_resource_id         = azurerm_storage_account.datalake_gen2.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "StorageRead"
    enabled  = true
  }
  log {
    category = "StorageWrite"
    enabled  = true
  }
  log {
    category = "StorageDelete"
    enabled  = true
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
  metric {
    category = "Capacity"
    enabled  = true
  }
}

# --- Action Group for Alerts ---
resource "azurerm_monitor_action_group" "main" {
  name                = var.action_group_name
  resource_group_name = azurerm_resource_group.main.name
  short_name          = var.action_group_short_name

  email_receiver {
    name          = "admin_email"
    email_address = var.admin_email_for_alerts
  }

  # Add other receivers like SMS, Webhook, etc., if needed
}

# --- Metric Alerts ---

# Function App: HTTP 5xx Errors Alert
resource "azurerm_monitor_metric_alert" "function_app_http_errors_alert" {
  name                     = "func-app-http-5xx-errors-alert"
  resource_group_name      = azurerm_resource_group.main.name
  scopes                   = [azurerm_linux_function_app.main.id]
  description              = "Alert when Function App experiences high rate of HTTP 5xx errors."
  target_resource_type     = azurerm_linux_function_app.main.type
  target_resource_location = azurerm_linux_function_app.main.location
  enabled                  = true
  frequency                = "PT5M" # Check every 5 minutes
  window_size              = "PT5M" # Look at data from the last 5 minutes

  criteria {
    metric_namespace = "microsoft.web/sites"
    metric_name      = "Http5xxErrors"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5 # More than 5 errors in 5 minutes
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
  target_resource_type     = azurerm_mssql_database.main.type
  target_resource_location = azurerm_mssql_database.main.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT15M" # Average over 15 minutes

  criteria {
    metric_namespace = "microsoft.sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80 # Alert if average DTU consumption is over 80%
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# IoT Hub: Telemetry Message Errors Alert
resource "azurerm_monitor_metric_alert" "iot_hub_telemetry_errors_alert" {
  name                     = "iot-hub-telemetry-errors-alert"
  resource_group_name      = azurerm_resource_group.main.name
  scopes                   = [azurerm_iot_hub.main.id]
  description              = "Alert when IoT Hub telemetry messages have errors."
  target_resource_type     = azurerm_iot_hub.main.type
  target_resource_location = azurerm_iot_hub.main.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT5M"

  criteria {
    metric_namespace = "microsoft.devices/iothubs"
    metric_name      = "d2c.telemetry.ingress.errors"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0 # Alert on any telemetry ingress errors
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
  target_resource_type     = azurerm_storage_account.datalake_gen2.type
  target_resource_location = azurerm_storage_account.datalake_gen2.location
  enabled                  = true
  frequency                = "PT5M"
  window_size              = "PT5M"

  criteria {
    metric_namespace = "microsoft.storage/storageaccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0 # Alert on any transaction errors
    dimension {
      name     = "ResponseType"
      operator = "Include"
      values   = ["ServerOtherError", "ClientOtherError"] # Filter for error responses
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}