# main.tf - Root module: wires networking, compute and database together.
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  project_name_random = "${var.project_name}-${random_id.suffix.hex}"
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

resource "azurerm_role_assignment" "agic_vnet_network_contributor" {
  scope                = module.networking.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.ingress_identity_id
}

# ── Docker Build & Push ────────────────────────────────────────────────────────
resource "null_resource" "docker_push" {
  triggers = {
    # Re-run if the dashboard files change
    hash = sha1(join("", [for f in fileset("${path.module}/../dashboard", "*") : filebase64("${path.module}/../dashboard/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOF
      az acr login --name ${module.acr.acr_name}
      docker build -t ${module.acr.login_server}/fortress-dashboard:v2 ${path.module}/../dashboard
      docker push ${module.acr.login_server}/fortress-dashboard:v2
    EOF
  }

  depends_on = [module.acr]
}

# ── Kubernetes Deployment ──────────────────────────────────────────────────────
resource "kubernetes_deployment" "fortress_web" {
  depends_on = [null_resource.docker_push, module.aks]

  metadata {
    name = "fortress-web-${random_id.suffix.hex}"
    labels = {
      app = "fortress"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "fortress"
      }
    }

    template {
      metadata {
        labels = {
          app = "fortress"
        }
      }

      spec {
        container {
          name  = "fortress-dashboard"
          image = "${module.acr.login_server}/fortress-dashboard:v2"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "fortress_service" {
  metadata {
    name = "fortress-service-${random_id.suffix.hex}"
  }

  spec {
    selector = {
      app = "fortress"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "fortress_ingress" {
  metadata {
    name = "fortress-ingress-${random_id.suffix.hex}"
  }

  spec {
    ingress_class_name = "azure-application-gateway"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.fortress_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
