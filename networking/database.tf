# database.tf

# 1. Private DNS Zone for internal resolution
resource "azurerm_private_dns_zone" "db_zone" {
  name                = "${var.project_name}-db.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

# 2. Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "db_zone_link" {
  name                  = "${var.project_name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.db_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name
}

# 3. PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "${lower(var.project_name)}-db" # Must be globally unique and lowercase
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"                    # Check latest supported via Azure CLI
  delegated_subnet_id    = azurerm_subnet.db[0].id # Delegated subnet required
  private_dns_zone_id    = azurerm_private_dns_zone.db_zone.id
  administrator_login    = var.admin_username
  administrator_password = var.db_password
  zone                   = "1"   # Use an availability zone
  storage_mb             = 32768 # 32 GB

  public_network_access_enabled = false

  sku_name = "B_Standard_B1ms" # Burstable tier

  depends_on = [azurerm_private_dns_zone_virtual_network_link.db_zone_link]
}
