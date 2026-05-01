# modules/app_gateway/app_gateway.tf

resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.project_name}-appgw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_address_pool_name      = "${var.project_name}-beap"
  frontend_port_name             = "${var.project_name}-feport"
  frontend_ip_configuration_name = "${var.project_name}-feip"
  http_setting_name              = "${var.project_name}-be-htst"
  listener_name                  = "${var.project_name}-httplstn"
  request_routing_rule_name      = "${var.project_name}-rqrt"
  redirect_configuration_name    = "${var.project_name}-rdrcfg"
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name = var.sku_name
    tier = var.sku_tier
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                                = 3000
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "fortress-health-probe"
    pick_host_name_from_backend_address = true
  }

  probe {
    name                                = "fortress-health-probe"
    protocol                            = "Http"
    path                                = "/health"
    interval                            = 30
    timeout                             = 30
    unhealthy_threshold                 = 3
    pick_host_name_from_backend_http_settings = true
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 10000
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      request_routing_rule,
      probe,
      tags
    ]
  }

  tags = {
    Environment = "Production"
    Project     = var.project_name
  }
}
