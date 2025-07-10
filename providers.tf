# providers.tf
# This file defines the required Terraform providers and their configuration.

# Configure the AzureRM Provider
# This block specifies the Azure provider and its version.
# It's good practice to pin the provider version for consistency.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" 
    }
  }
}

# Provider configuration for Azure.
# Features block is often used for specific provider features,
# but for basic setup, it can be empty.
provider "azurerm" {
  features {}
}