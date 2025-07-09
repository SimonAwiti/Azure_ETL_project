# variables.tf
# This file contains all input variables for the Terraform configuration.

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-ra-etl-architecture-demo" # Updated name
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "australiacentral" # Updated region
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
  default     = "snet-ra-etl-app"
}

variable "app_subnet_address_prefixes" {
  description = "The address prefix for the Application Subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "db_subnet_name" {
  description = "The name of the DB Subnet."
  type        = string
  default     = "snet-ra-etl-db"
}

variable "db_subnet_address_prefixes" {
  description = "The address prefix for the DB Subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "analytics_subnet_name" {
  description = "The name of the Analytics Subnet."
  type        = string
  default     = "snet-ra-etl-analytics"
}

variable "analytics_subnet_address_prefixes" {
  description = "The address prefix for the Analytics Subnet."
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

variable "function_app_name" {
  description = "The name of the Azure Function App."
  type        = string
  default     = "func-ra-etl-architecture-demo" # Updated name
}

variable "function_app_storage_name" {
  description = "The name of the storage account for the Function App."
  type        = string
  default     = "raetlfuncarchdemo" # Updated name for global uniqueness
}

variable "datalake_storage_name" {
  description = "The name of the Data Lake Gen2 storage account."
  type        = string
  default     = "raetldatalakearchdemo" # Updated name for global uniqueness
}

variable "sql_server_name" {
  description = "The name of the Azure SQL Server."
  type        = string
  default     = "sqlserver-ra-etl-arch-demo" # Updated name
}

variable "sql_database_name" {
  description = "The name of the Azure SQL Database."
  type        = string
  default     = "sqldb-ra-etl-arch-demo" # Updated name
}

variable "sql_admin_login" {
  description = "The admin login for the Azure SQL Server."
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "The admin password for the Azure SQL Server."
  type        = string
  sensitive   = true                  # Mark as sensitive to prevent logging
  default     = "ComplexP@ssw0rd123!" # CHANGE THIS TO A STRONG PASSWORD
}

