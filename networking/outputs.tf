output "vnet_name" {
  description = "The name of the VNet"
  value       = module.networking.vnet_name
}

output "lb_public_ip" {
  description = "Public IP of the Load Balancer — paste into your browser"
  value       = module.compute.lb_public_ip
}



output "db_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server (resolve inside VNet only)"
  value       = module.database.db_server_fqdn
}

output "app_subnet_ids" {
  description = "IDs of the private App tier subnets"
  value       = module.networking.app_subnet_ids
}

output "state_storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "The name of the Azure Storage Account for Terraform state storage."
}

output "state_container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "The name of the Storage Container for Terraform state storage."
}

output "mgmt_resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}
