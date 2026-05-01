# modules/networking/outputs.tf

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "The resource ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "app_subnet_ids" {
  description = "IDs of the private app subnets"
  value       = azurerm_subnet.app[*].id
  depends_on  = [azurerm_subnet_network_security_group_association.unified]
}

output "db_delegated_subnet_id" {
  description = "ID of the delegated DB subnet for PostgreSQL"
  value       = azurerm_subnet.db_delegated.id
}

output "resource_group_name" {
  description = "Name of the shared resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the shared resource group"
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "The ID of the shared resource group"
  value       = azurerm_resource_group.main.id
}

output "gateway_subnet_id" {
  description = "ID of the gateway subnet"
  value       = azurerm_subnet.gateway.id
  depends_on  = [azurerm_subnet_network_security_group_association.unified]
}

output "bastion_subnet_id" {
  description = "ID of the Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "redis_subnet_id" {
  description = "ID of the Redis subnet"
  value       = azurerm_subnet.redis.id
}
