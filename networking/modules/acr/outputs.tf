# modules/acr/outputs.tf

output "acr_id" {
  value = azurerm_container_registry.main.id
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "login_server" {
  value = azurerm_container_registry.main.login_server
}

output "admin_username" {
  value = azurerm_container_registry.main.admin_username
}

output "admin_password" {
  value     = azurerm_container_registry.main.admin_password
  sensitive = true
}
