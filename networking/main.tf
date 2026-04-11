# main.tf - Root module: wires networking, compute and database together.
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  project_name_random = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
}

# ── Networking module ──────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name       = local.project_name_random
  location           = var.location
  vnet_address_space = var.vnet_address_space
  ssh_allowed_source = var.ssh_allowed_source
}

# ── AKS module ──────────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  project_name        = local.project_name_random
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  node_vm_size        = var.vm_size
  vnet_subnet_id      = module.networking.app_subnet_ids[0]
  gateway_id          = module.app_gateway.appgw_id
  gateway_subnet_id   = module.networking.gateway_subnet_id
  min_count            = var.min_count
  max_count            = var.max_count
  authorized_ip_ranges = var.aks_authorized_ip_ranges
  environment          = var.environment
}

# ── Database module ────────────────────────────────────────────────────────────
# ... (existing database module)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "database" {
  source = "./modules/database"

  project_name        = local.project_name_random
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  db_name             = var.db_name
  admin_username      = var.admin_username
  db_password         = random_password.db_password.result
  db_subnet_ids       = module.networking.db_subnet_ids
  vnet_id             = module.networking.vnet_id
  vnet_name           = module.networking.vnet_name
}

# ── Application Gateway module ─────────────────────────────────────────────────
module "app_gateway" {
  source = "./modules/app_gateway"

  project_name        = local.project_name_random
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.gateway_subnet_id
}

# ── ACR module ─────────────────────────────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  project_name        = local.project_name_random
  location            = var.location
  resource_group_name = module.networking.resource_group_name
}

# ── Bastion module ─────────────────────────────────────────────────────────────
module "bastion" {
  source = "./modules/bastion"

  project_name        = local.project_name_random
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.bastion_subnet_id
}

# ── Redis module ───────────────────────────────────────────────────────────────
module "redis" {
  source = "./modules/redis"

  project_name        = local.project_name_random
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.redis_subnet_id
  vnet_id             = module.networking.vnet_id
}

# Grant AKS pull permission from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.aks.kubelet_identity_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.acr_id
  skip_service_principal_aad_check = true
}

# AGIC Role Assignments
# 1. Grant Reader to the Resource Group
resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = module.networking.resource_group_id
  role_definition_name = "Reader"
  principal_id         = module.aks.ingress_identity_id
}

# 2. Grant Contributor to the App Gateway
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = module.app_gateway.appgw_id
  role_definition_name = "Contributor"
  principal_id         = module.aks.ingress_identity_id
}

# 3. Grant Network Contributor to the Virtual Network (Required for AGIC Sync)
resource "azurerm_role_assignment" "agic_vnet_contributor" {
  scope                = module.networking.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.ingress_identity_id
}


