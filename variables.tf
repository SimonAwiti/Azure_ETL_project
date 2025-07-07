variable "location" {
  description = "Azure region where resources will be deployed"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "ra-vnet-rg"
}
variable "vnet_name" {
  description = "Name of the virtual network"
  default     = "ra-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

# Subnets
variable "analytics_subnet_name" {
  description = "Name of the analytics subnet"
  default     = "analytics-subnet"
}

variable "analytics_subnet_address" {
  description = "Address space for the analytics subnet"
  default     = ["10.0.1.0/24"]
}

variable "app_subnet_name" {
  description = "Name of the application subnet"
  default     = "app-subnet"
}

variable "app_subnet_address" {
  description = "Address space for the application subnet"
  default     = ["10.0.2.0/24"]
}

variable "storage_subnet_name" {
  description = "Name of the storage subnet"
  default     = "storage-subnet"
}

variable "storage_subnet_address" {
  description = "Address space for the storage subnet"
  default     = ["10.0.3.0/24"]
}
#Resourses

variable "storage_account_name" {
  description = "Name of the storage account"
  default     = "radatalake"
}

