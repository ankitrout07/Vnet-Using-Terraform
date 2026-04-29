# modules/app_gateway/outputs.tf

output "appgw_id" {
  value = azurerm_application_gateway.main.id
}

output "appgw_name" {
  value = azurerm_application_gateway.main.name
}

output "public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "public_ip_id" {
  value = azurerm_public_ip.appgw_pip.id
}
