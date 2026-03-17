# backend-init/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}O
}

variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "rg-terraform-mgmt-prod"
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

# Generate a random string for unique storage account name
resource "random_string" "storage_account_name" {
  length  = 16
  special = false
  upper   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_string.storage_account_name.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
