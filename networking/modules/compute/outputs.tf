# modules/compute/outputs.tf

output "lb_public_ip" {
  description = "Public IP address of the Load Balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}



output "vmss_id" {
  description = "Resource ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.app.id
}
