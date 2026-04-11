# variables.tf

variable "environment" {
  description = "The deployment environment (dev, prod, etc)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure region to deploy to"
  type        = string
  default     = "Central India" # Reverting to Central India as South India is restricted by policy
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
  default     = "Standard_D2s_v3" # Total vCPU quota in Central India is 6
}

variable "db_name" {
  description = "Name of the Postgres database"
  type        = string
  default     = "fortressdb"
}

variable "min_count" {
  description = "Minimum number of nodes in the AKS cluster"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of nodes in the AKS cluster (staying within quota 6)"
  type        = number
  default     = 3
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

variable "ssh_allowed_source" {
  description = "Source IP range allowed to SSH into Bastion"
  type        = string
  default     = "*" # Restricted to user's IP in production
}

variable "aks_authorized_ip_ranges" {
  description = "List of authorized IP ranges to access the AKS API server"
  type        = list(string)
  default     = []
}