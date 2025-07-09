# variables.tf
# This file contains all input variables for the Terraform configuration.

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-ra-etl-architecture-demo"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "UK West"
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
  default     = "vnet-ra-etl-architecture-demo"
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_name" {
  description = "The name of the Application Subnet."
  type        = string
  default     = "app-snet-ra-etl"
}

variable "app_subnet_address_prefixes" {
  description = "The address prefix for the Application Subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "db_subnet_name" {
  description = "The name of the DB Subnet for Private Endpoint."
  type        = string
  default     = "db-snet-ra-etl"
}

variable "db_subnet_address_prefixes" {
  description = "The address prefix for the DB Subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "datalake_subnet_name" {
  description = "The name of the Data Lake Subnet for Private Endpoint."
  type        = string
  default     = "datalake-snet-ra-etl"
}

variable "datalake_subnet_address_prefixes" {
  description = "The address prefix for the Data Lake Subnet."
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

variable "function_app_name" {
  description = "The name of the Azure Function App."
  type        = string
  default     = "func-app-ra-etl"
}

variable "function_app_storage_name" {
  description = "The name of the storage account for the Function App."
  type        = string
  default     = "func-app-ra-etl-strge"
}

variable "datalake_storage_name" {
  description = "The name of the Data Lake Gen2 storage account."
  type        = string
  default     = "dtlake-app-ra-etl-strge"
}

variable "sql_server_name" {
  description = "The name of the Azure SQL Server."
  type        = string
  default     = "sqlserver-ra-etl"
}

variable "sql_database_name" {
  description = "The name of the Azure SQL Database."
  type        = string
  default     = "sqldb-ra-etl"
}

variable "sql_admin_login" {
  description = "The admin login for the Azure SQL Server."
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "The admin password for the Azure SQL Server."
  type        = string
  sensitive   = true
  default     = "ComplexP@ssw0rd123!" # CHANGE THIS TO A STRONG PASSWORD
}

variable "iot_hub_name" {
  description = "The name of the Azure IoT Hub."
  type        = string
  default     = "iothub-ra-etl"
}

variable "iot_hub_consumer_group_name" {
  description = "The name of the consumer group for the IoT Hub built-in endpoint."
  type        = string
  default     = "functionapp-consumer-group"
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace."
  type        = string
  default     = "loganalytics-ra-etl-demo"
}

variable "app_insights_name" {
  description = "The name of the Application Insights resource."
  type        = string
  default     = "appinsights-ra-etl-demo"
}

variable "action_group_name" {
  description = "The name of the Azure Monitor Action Group."
  type        = string
  default     = "actiongroup-ra-etl-demo"
}

variable "action_group_short_name" {
  description = "The short name for the Azure Monitor Action Group."
  type        = string
  default     = "ra-alerts"
}

variable "admin_email_for_alerts" {
  description = "The email address to send alert notifications to."
  type        = string
  default     = "awitisimon23@gmail.com"
}