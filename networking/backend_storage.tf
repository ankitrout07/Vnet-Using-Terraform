# backend_storage.tf - Infrastructure for storing Terraform state.


# Generate a random string for unique storage account name
resource "random_string" "storage_account_name" {
  length  = 16
  special = false
  upper   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_string.storage_account_name.result}"
  resource_group_name      = module.networking.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

output "tfstate_storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}
