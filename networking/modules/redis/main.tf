# modules/redis/main.tf

resource "azurerm_redis_cache" "redis" {
  name                = "${var.project_name}-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}

resource "azurerm_private_endpoint" "redis_pe" {
  name                = "${var.project_name}-redis-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.project_name}-redis-connection"
    private_connection_resource_id = azurerm_redis_cache.redis.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }
}

resource "azurerm_private_dns_zone" "redis_dns" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis_dns_link" {
  name                  = "${var.project_name}-redis-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis_dns.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_a_record" "redis_dns_a" {
  name                = lower(azurerm_redis_cache.redis.name)
  zone_name           = azurerm_private_dns_zone.redis_dns.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis_pe.private_service_connection[0].private_ip_address]
}
