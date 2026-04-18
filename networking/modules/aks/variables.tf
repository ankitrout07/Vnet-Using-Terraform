# modules/aks/variables.tf

variable "project_name" {
  description = "Unique name to prefix all resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region for AKS resources"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.29.9"
}

variable "node_vm_size" {
  description = "SKU for the AKS node pool VMs (Standard_B2s is 2 vCPU, 4GB RAM)"
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "min_count" {
  description = "Minimum number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "vnet_subnet_id" {
  description = "ID of the subnet where AKS nodes and pods will reside"
  type        = string
}

variable "gateway_id" {
  description = "The ID of the Application Gateway to associate with AGIC"
  type        = string
}

variable "gateway_subnet_id" {
  description = "The ID of the subnet where the Application Gateway resides"
  type        = string
}

variable "authorized_ip_ranges" {
  description = "List of authorized IP ranges to access the AKS API server"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "The deployment environment (dev, prod, etc)"
  type        = string
  default     = "dev"
}
