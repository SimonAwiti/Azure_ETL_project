variable "location" {
  description = "Azure region where resources will be deployed"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "ra-vnet-rg"
}
