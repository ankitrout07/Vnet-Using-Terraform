# database.tf - Rewritten to use Azure PostgreSQL Flexible Server

resource "random_string" "db_suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Private DNS Zone for PostgreSQL Flexible Server
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${lower(var.project_name)}-${random_string.db_suffix.result}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

# 3. Link the Private DNS Zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.project_name}-pg-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# 4. PostgreSQL Flexible Server (replaces old MSSQL)
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${lower(var.project_name)}-pg-${random_string.db_suffix.result}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "15"
  delegated_subnet_id    = var.delegated_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = var.admin_username
  administrator_password = var.db_password

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms" # Cost-efficient: 1 vCore, 2GB RAM

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# 5. PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
