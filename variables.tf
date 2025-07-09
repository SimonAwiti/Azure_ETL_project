variable "resource_group_name" {
  description = "Name of existing resource group"
  default     = "ra-etl-pipeline-rg"
}

variable "vnet_name" {
  description = "Name of virtual network"
  default     = "ra-vnet"
}

variable "vnet_address_space" {
  description = "VNet address space"
  default     = ["10.1.0.0/16"] # Updated for Australia deployment
}

variable "analytics_subnet_name" {
  description = "Analytics subnet name"
  default     = "analytics-subnet"
}

variable "analytics_subnet_address" {
  description = "Analytics subnet range"
  default     = ["10.1.1.0/24"]
}

variable "app_subnet_name" {
  description = "App subnet name"
  default     = "app-subnet"
}

variable "app_subnet_address" {
  description = "App subnet range"
  default     = ["10.1.2.0/24"]
}

variable "storage_subnet_name" {
  description = "Name of the storage subnet"
  default     = "storage-subnet"
}

variable "storage_subnet_address" {
  description = "Address space for the storage subnet"
  default     = ["10.0.3.0/24"]
}

# Resources
variable "storage_account_name" {
  description = "Storage account name"
  default     = "raetldatalakeaus"
}

variable "function_app_name" {
  description = "Function app name"
  default     = "ra-func-aus"
}