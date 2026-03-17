# backend-init/outputs.tf

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "The name of the Azure Storage Account generated for Terraform state storage. Update networking/provider.tf with this name."
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}
