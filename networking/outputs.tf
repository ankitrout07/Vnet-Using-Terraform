output "vnet_name" {
  description = "The name of the VNet"
  value       = module.networking.vnet_name
}

output "aks_cluster_name" {
  description = "Name of the Azure Kubernetes Service cluster"
  value       = module.aks.cluster_name
}

output "app_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = module.app_gateway.public_ip
}

output "acr_login_server" {
  description = "The login server for the Azure Container Registry"
  value       = module.acr.login_server
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

output "resource_group_name" {
  description = "The main resource group name"
  value       = module.networking.resource_group_name
}

output "appgw_id" {
  description = "ID of the Application Gateway"
  value       = module.app_gateway.appgw_id
}

output "aks_cluster_id" {
  description = "ID of the Azure Kubernetes Service cluster"
  value       = module.aks.cluster_id
}

output "db_server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = module.database.db_server_id
}

output "db_password" {
  description = "Administrator password for the database"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_username" {
  description = "Administrator username for the database"
  value       = var.admin_username
}

output "db_name" {
  description = "Name of the database"
  value       = var.db_name
}
