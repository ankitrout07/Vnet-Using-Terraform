# main.tf - Root module: wires networking, compute and database together.

# ── Networking module ──────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  location           = var.location
  vnet_address_space = var.vnet_address_space
  ssh_allowed_source = var.ssh_allowed_source
}

# ── AKS module (Replaces VMSS) ──────────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  node_vm_size        = var.vm_size
  vnet_subnet_id      = module.networking.app_subnet_ids[0]
  gateway_id          = module.app_gateway.appgw_id
  gateway_subnet_id   = module.networking.gateway_subnet_id
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

  project_name        = var.project_name
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

  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.gateway_subnet_id
}

# ── ACR module ─────────────────────────────────────────────────────────────────
module "acr" {
  source = "./modules/acr"

  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.resource_group_name
}

# Grant AKS pull permission from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.aks.principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.acr_id
  skip_service_principal_aad_check = true
}

# AGIC Role Assignments
# 1. Grant Reader to the Resource Group
resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = "/subscriptions/7ef42162-83d2-4247-8010-38bf34dd1453/resourceGroups/Fortress-VNet-rg"
  role_definition_name = "Reader"
  principal_id         = "36adc1ec-d3a2-4a48-a306-843725c42a6b" # Object ID from your logs
}

# 2. Grant Contributor to the App Gateway
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = "/subscriptions/7ef42162-83d2-4247-8010-38bf34dd1453/resourceGroups/Fortress-VNet-rg/providers/Microsoft.Network/applicationGateways/Fortress-VNet-appgw"
  role_definition_name = "Contributor"
  principal_id         = "36adc1ec-d3a2-4a48-a306-843725c42a6b"
}

resource "azurerm_role_assignment" "agic_vnet_network_contributor" {
  scope                = module.networking.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.principal_id
}
