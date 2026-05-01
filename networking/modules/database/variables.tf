# modules/database/variables.tf

variable "project_name" {
  description = "Unique name to prefix all resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region for database resources"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "fortressdb"
}

variable "admin_username" {
  description = "Admin username for the database server"
  type        = string
  default     = "adminuser"
}

variable "db_password" {
  description = "Admin password for the database server"
  type        = string
  sensitive   = true
}

variable "delegated_subnet_id" {
  description = "The ID of the delegated subnet for the Postgres Flexible Server"
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the VNet for Private DNS zone linking"
  type        = string
}

variable "vnet_name" {
  description = "Name of the VNet"
  type        = string
}


