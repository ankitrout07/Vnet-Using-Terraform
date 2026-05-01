# security.tf - Unified NSG Configuration

# --- UNIFIED NETWORK SECURITY GROUP ---
resource "azurerm_network_security_group" "unified_nsg" {
  name                = "${var.project_name}-unified-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # 1. Mandatory Gateway Infrastructure (Highest Priority for v2 SKU)
  security_rule {
    name                       = "Allow-GatewayManager-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # 2. Web Traffic (ALB / Gateway / App)
  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # 3. Management (Bastion / SSH)
  security_rule {
    name                       = "Allow-SSH-External"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_source
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Internal"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # 4. Application Services
  security_rule {
    name                       = "Allow-App-Port-3000"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # 5. Database Tier
  security_rule {
    name                       = "Allow-PostgreSQL-Inbound"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # 6. Global Security
  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# --- UNIFIED ASSOCIATION LOGIC ---
locals {
  # Define all subnets that should be associated with the unified NSG
  subnets_to_associate = merge(
    { for i in range(2) : "public-${i}" => azurerm_subnet.public[i].id },
    { for i in range(2) : "app-${i}" => azurerm_subnet.app[i].id },
    { for i in range(2) : "db-${i}" => azurerm_subnet.db[i].id },
    { "gateway" = azurerm_subnet.gateway.id },
    { "redis"   = azurerm_subnet.redis.id },
    { "pg"      = azurerm_subnet.postgres_delegated.id }
    # Note: AzureBastionSubnet excluded from unified NSG as it requires 
    # very specific, mandatory rules for Azure Bastion Service compliance.
  )
}

resource "azurerm_subnet_network_security_group_association" "unified" {
  for_each                  = local.subnets_to_associate
  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.unified_nsg.id
}
