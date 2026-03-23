# variables.tf

variable "location" {
  description = "The Azure region to deploy to"
  type        = string
  default     = "South India" # Switching to South India as Central India is completely out of quota
}

variable "mgmt_resource_group_name" {
  description = "Name of the resource group for management/state resources"
  type        = string
  default     = "rg-terraform-mgmt-prod"
}

variable "vnet_address_space" {
  description = "Base Address Space for the VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  type    = string
  default = "Fortress-VNet"
}

variable "vm_size" {
  description = "VM size for application servers"
  type        = string
  default     = "Standard_D2s_v3" # The only size available in Central India, limited to 4 cores total
}

variable "db_name" {
  description = "Name of the Postgres database"
  type        = string
  default     = "fortressdb"
}

variable "admin_username" {
  description = "Admin username for VMs and DB"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Password for VMs (sensitive)"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # In production, use Key Vault
}

variable "db_password" {
  description = "Password for the database administrator"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_source" {
  description = "Source IP range allowed to SSH into Bastion"
  type        = string
  default     = "*" # Restricted to user's IP in production
}