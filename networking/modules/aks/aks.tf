# modules/aks/aks.tf

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.project_name}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                    = "${var.project_name}-aks"
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = "${lower(var.project_name)}-k8s"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true # Private AKS Cluster
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  default_node_pool {
    name                = "systempool"
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = true
    min_count           = var.min_count
    max_count           = var.max_count
    
    # Required for small clusters to fit in quota
    os_disk_size_gb = 32
    type            = "VirtualMachineScaleSets"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  network_profile {
    network_plugin    = "azure" # Azure CNI 
    load_balancer_sku = "standard"
    # CNI defaults for networking
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  ingress_application_gateway {
    gateway_id = var.gateway_id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
