# Azure Hub-and-Spoke Network Architecture
# Environment-based spokes (dev, uat, prod) with web, app, and db subnets per environment
# Following Azure Well-Architected Framework Pillars:
# - Reliability: Multi-zone resources, redundant connectivity
# - Security: Azure Firewall, NSGs, Bastion for secure access
# - Cost Optimization: Right-sized resources per environment, efficient routing
# - Operational Excellence: Consistent tagging, modular design
# - Performance Efficiency: Optimized network paths

###############################################################################
# HUB RESOURCES
###############################################################################

# Resource Group for Hub Resources
resource "azurerm_resource_group" "hub" {
  name     = "${var.prefix}-hub-rg"
  location = var.location
  tags     = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Hub VNet - Central hub for connectivity and security services
resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-hub-vnet"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.hub_vnet_address_space]
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Azure Firewall Subnet (name must be AzureFirewallSubnet)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_firewall_subnet_prefix]
}

# Azure Bastion Subnet (name must be AzureBastionSubnet)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_bastion_subnet_prefix]
}

# Gateway Subnet for future VPN/ExpressRoute connectivity
resource "azurerm_subnet" "gateway" {
  count                = var.deploy_gateway_subnet ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_gateway_subnet_prefix]
}

# Management Subnet for jump boxes and management tools
resource "azurerm_subnet" "management" {
  name                 = "${var.prefix}-mgmt-subnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_management_subnet_prefix]
}

###############################################################################
# AZURE FIREWALL
###############################################################################

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "${var.prefix}-fw-pip"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Firewall Policy
resource "azurerm_firewall_policy" "main" {
  name                     = "${var.prefix}-fw-policy"
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = azurerm_resource_group.hub.location
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Alert"

  dns {
    proxy_enabled = false
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Firewall Policy Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  depends_on         = [azurerm_firewall_policy.main]
  name               = "${var.prefix}-fw-rcg"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100
}

# ============================================================================
# NETWORK RULE COLLECTIONS
# ============================================================================

# 1. Allow spoke-to-spoke communication If needed (Dev <-> UAT)
# Note: In Hub and Spoke - Spokes are not allowed to communicate directly with each other. All traffic must go through the Hub and be inspected by the Firewall. This is a key security principle of the architecture.

resource "azurerm_firewall_policy_rule_collection_group" "pazure_rules" {
  name = "pazure-firewall-rule-group"
  # Replace 'azurerm_firewall_policy.main.id' with the actual resource name of your policy
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 500

  # 1. DevSpoke-to-UATSpoke Rules
  network_rule_collection {
    name     = "devspoke-to-uatspoke-rules"
    priority = 150
    action   = "Allow"

    rule {
      name                  = "dev-to-uat"
      protocols             = ["Any"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.2.0.0/16"]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "uat-to-dev"
      protocols             = ["Any"]
      source_addresses      = ["10.2.0.0/16"]
      destination_addresses = ["10.1.0.0/16"]
      destination_ports     = ["*"]
    }
  }

  # 2. Spoke-to-Onprem Rules
  network_rule_collection {
    name     = "spoke-to-onprem-rules"
    priority = 140
    action   = "Allow"

    rule {
      name                  = "spokes-to-onprem"
      protocols             = ["Any"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_addresses = ["10.10.0.0/16"]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "onprem-to-spokes"
      protocols             = ["Any"]
      source_addresses      = ["10.10.0.0/16"]
      destination_addresses = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_ports     = ["*"]
    }
  }

  # 3. Internet Access Rules
  network_rule_collection {
    name     = "internet-access-explicit"
    priority = 130
    action   = "Allow"

    rule {
      name                  = "allow-internet-public-ips"
      protocols             = ["Any"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }

  # # 4. Block Private Ranges
  # network_rule_collection {
  #   name     = "block-private-ip-ranges"
  #   priority = 120
  #   action   = "Deny"

  #   rule {
  #     name      = "deny-private-ranges"
  #     protocols = ["Any"]
  #     source_addresses = [
  #       "10.1.0.0/16",
  #       "10.2.0.0/16",
  #     ]
  #     destination_addresses = [
  #       "10.0.0.0/8",
  #       "172.16.0.0/12",
  #       "192.168.0.0/16",
  #       "127.0.0.0/8",
  #       "169.254.0.0/16",
  #     ]
  #     destination_ports = ["*"]
  #   }
  # }

  # 5. Application Rules for Web/Internet Access
  application_rule_collection {
    name     = "spokes-internet-rules"
    priority = 200
    action   = "Allow"

    rule {
      name = "allow-spokes-web-browsing"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_fqdns = [
        "*.microsoft.com",
        "*.windows.net",
        "*.azure.com",
        "*.ubuntu.com",
        "*.debian.org",
        "github.com",
        "*.github.com",
        "*.githubusercontent.com",
      ]
    }

    rule {
      name = "allow-dev-package-managers"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_fqdns = [
        "*.pypi.org",
        "*.npmjs.org",
        "registry.npmjs.org",
        "*.nuget.org",
        "packages.microsoft.com",
      ]
    }
  }
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  name                = "${var.prefix}-firewall"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.main.id
  #  zones               = var.availability_zones

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

###############################################################################
# AZURE BASTION
###############################################################################

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "${var.prefix}-bastion-pip"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = "${var.prefix}-bastion"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = var.bastion_sku

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

##############################################################################
# SPOKE VNETS - ENVIRONMENT BASED (dev, uat, prod)
##############################################################################

# Resource Groups for Spoke VNets
resource "azurerm_resource_group" "spoke" {
  for_each = toset(var.environments)

  name     = "${var.prefix}-spoke-${each.key}-rg"
  location = var.location
  tags     = merge(local.common_tags, { environment = each.key })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Spoke VNets
resource "azurerm_virtual_network" "spoke" {
  for_each = toset(var.environments)

  name                = "${var.prefix}-spoke-${each.key}-vnet"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  address_space       = [var.spoke_vnet_address_spaces[each.key].vnet_cidr]
  tags                = merge(local.common_tags, { environment = each.key })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Web Tier Subnets
resource "azurerm_subnet" "web" {
  for_each = toset(var.environments)

  name                 = "${var.prefix}-${each.key}-web-subnet"
  resource_group_name  = azurerm_resource_group.spoke[each.key].name
  virtual_network_name = azurerm_virtual_network.spoke[each.key].name
  address_prefixes     = [var.spoke_vnet_address_spaces[each.key].web_subnet_cidr]
}

# App Tier Subnets
resource "azurerm_subnet" "app" {
  for_each = toset(var.environments)

  name                 = "${var.prefix}-${each.key}-app-subnet"
  resource_group_name  = azurerm_resource_group.spoke[each.key].name
  virtual_network_name = azurerm_virtual_network.spoke[each.key].name
  address_prefixes     = [var.spoke_vnet_address_spaces[each.key].app_subnet_cidr]
}

# DB Tier Subnets
resource "azurerm_subnet" "db" {
  for_each = toset(var.environments)

  name                 = "${var.prefix}-${each.key}-db-subnet"
  resource_group_name  = azurerm_resource_group.spoke[each.key].name
  virtual_network_name = azurerm_virtual_network.spoke[each.key].name
  address_prefixes     = [var.spoke_vnet_address_spaces[each.key].db_subnet_cidr]
}

###############################################################################
# VNET PEERING - HUB TO SPOKES
###############################################################################

# Hub to Spoke Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = toset(var.environments)

  name                         = "hub-to-${each.key}-peering"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  #  depends_on = [ azurerm_virtual_network.spoke ]
}

# Spoke to Hub Peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = toset(var.environments)

  name                         = "${each.key}-to-hub-peering"
  resource_group_name          = azurerm_resource_group.spoke[each.key].name
  virtual_network_name         = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

###############################################################################
# ROUTE TABLES - Force traffic through Azure Firewall
###############################################################################

# Route Tables for Spokes Subnets
resource "azurerm_route_table" "spokes" {
  for_each = toset(var.environments)

  name                          = "${var.prefix}-${each.key}-spoke-rt"
  location                      = azurerm_resource_group.spoke[each.key].location
  resource_group_name           = azurerm_resource_group.spoke[each.key].name
  bgp_route_propagation_enabled = true
  tags                          = merge(local.common_tags, { environment = each.key })
  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

resource "azurerm_route" "outbound_internet" {
  for_each = toset(var.environments)

  name                   = "Outbount-Internet"
  resource_group_name    = azurerm_resource_group.spoke[each.key].name
  route_table_name       = azurerm_route_table.spokes[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "outbound_onprem" {
  for_each = toset(var.environments)

  name                   = "Outbount-Onprem"
  resource_group_name    = azurerm_resource_group.spoke[each.key].name
  route_table_name       = azurerm_route_table.spokes[each.key].name
  address_prefix         = "10.10.0.0/16" # Assuming on-premises network CIDR
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

# Route to UAT spoke through the firewall
locals {
  dev_env = ["dev"]
}
resource "azurerm_route" "outbound_dev" {
  for_each = toset(local.dev_env)

  name                   = "to-uat-spoke-vnet"
  resource_group_name    = azurerm_resource_group.spoke[each.key].name
  route_table_name       = azurerm_route_table.spokes[each.key].name
  address_prefix         = "10.2.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

# Route to spoke Dev through the firewall
locals {
  uat_env = ["uat"]
}
resource "azurerm_route" "outbound_uat" {
  for_each               = toset(local.uat_env)
  name                   = "to-dev-spoke-vnet"
  resource_group_name    = azurerm_resource_group.spoke[each.key].name
  route_table_name       = azurerm_route_table.spokes[each.key].name
  address_prefix         = "10.1.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
}


resource "azurerm_subnet_route_table_association" "web" {
  for_each = toset(var.environments)

  subnet_id      = azurerm_subnet.web[each.key].id
  route_table_id = azurerm_route_table.spokes[each.key].id
}

resource "azurerm_subnet_route_table_association" "app" {
  for_each = toset(var.environments)

  subnet_id      = azurerm_subnet.app[each.key].id
  route_table_id = azurerm_route_table.spokes[each.key].id
}

resource "azurerm_subnet_route_table_association" "db" {
  for_each = toset(var.environments)

  subnet_id      = azurerm_subnet.db[each.key].id
  route_table_id = azurerm_route_table.spokes[each.key].id
}

###############################################################################
# NETWORK SECURITY GROUPS
###############################################################################

# NSG for Web Tier
resource "azurerm_network_security_group" "web" {
  for_each = toset(var.environments)

  name                = "${var.prefix}-${each.key}-web-nsg"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  tags                = merge(local.common_tags, { environment = each.key, tier = "web" })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

resource "azurerm_network_security_rule" "web_deny_all_inbound" {
  for_each = toset(var.environments)

  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.web[each.key].name
}

resource "azurerm_network_security_rule" "web_allow_https" {
  for_each = toset(var.environments)

  name                        = "allow-http-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443", "22"]
  source_address_prefix       = "*"
  destination_address_prefix  = var.spoke_vnet_address_spaces[each.key].web_subnet_cidr
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.web[each.key].name
}

# Allow ICMP for troubleshooting Or to check the connectivity (ping)
resource "azurerm_network_security_rule" "web_allow_ping" {
  for_each = toset(var.environments)

  name                        = "allow-ping"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range     = "*"
  source_address_prefix       = "10.2.0.0/16" # Allow ping from UAT Spoke for testing connectivity
  destination_address_prefix  = var.spoke_vnet_address_spaces[each.key].web_subnet_cidr
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.web[each.key].name
}


resource "azurerm_subnet_network_security_group_association" "web" {
  for_each = toset(var.environments)

  subnet_id                 = azurerm_subnet.web[each.key].id
  network_security_group_id = azurerm_network_security_group.web[each.key].id
}

# NSG for App Tier
resource "azurerm_network_security_group" "app" {
  for_each = toset(var.environments)

  name                = "${var.prefix}-${each.key}-app-nsg"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  tags                = merge(local.common_tags, { environment = each.key, tier = "app" })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

resource "azurerm_network_security_rule" "app_deny_all_inbound" {
  for_each = toset(var.environments)

  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

resource "azurerm_network_security_rule" "app_allow_from_web" {
  for_each = toset(var.environments)

  name                        = "allow-from-web"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "8080"]
  source_address_prefix       = var.spoke_vnet_address_spaces[each.key].web_subnet_cidr
  destination_address_prefix  = var.spoke_vnet_address_spaces[each.key].app_subnet_cidr
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

# Allow ICMP for troubleshooting Or to check the connectivity (ping)
resource "azurerm_network_security_rule" "app_allow_ping" {
  for_each = toset(var.environments)

  name                        = "allow-ping"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range     = "*"
  source_address_prefix       = "10.1.0.0/16" # Allow ping from Dev Spoke for testing connectivity
  destination_address_prefix  = var.spoke_vnet_address_spaces[each.key].web_subnet_cidr
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

resource "azurerm_subnet_network_security_group_association" "app" {
  for_each = toset(var.environments)

  subnet_id                 = azurerm_subnet.app[each.key].id
  network_security_group_id = azurerm_network_security_group.app[each.key].id
}

# NSG for DB Tier
resource "azurerm_network_security_group" "db" {
  for_each = toset(var.environments)

  name                = "${var.prefix}-${each.key}-db-nsg"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  tags                = merge(local.common_tags, { environment = each.key, tier = "db" })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

resource "azurerm_network_security_rule" "db_deny_all_inbound" {
  for_each = toset(var.environments)

  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.db[each.key].name
}

resource "azurerm_network_security_rule" "db_allow_from_app" {
  for_each = toset(var.environments)

  name                        = "allow-from-app"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["1433", "3306", "5432"]
  source_address_prefix       = var.spoke_vnet_address_spaces[each.key].app_subnet_cidr
  destination_address_prefix  = var.spoke_vnet_address_spaces[each.key].db_subnet_cidr
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.db[each.key].name
}

# Allow ICMP for troubleshooting Or to check the connectivity (ping)
resource "azurerm_network_security_rule" "db_allow_ping" {
  for_each = toset(var.environments)

  name                        = "allow-ping"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range     = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = var.spoke_vnet_address_spaces[each.key].web_subnet_cidr
  resource_group_name         = azurerm_resource_group.spoke[each.key].name
  network_security_group_name = azurerm_network_security_group.db[each.key].name
}

resource "azurerm_subnet_network_security_group_association" "db" {
  for_each = toset(var.environments)

  subnet_id                 = azurerm_subnet.db[each.key].id
  network_security_group_id = azurerm_network_security_group.db[each.key].id
}

# NSG for Management Subnet in Hub
resource "azurerm_network_security_group" "management" {
  name                = "${var.prefix}-mgmt-nsg"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

resource "azurerm_network_security_rule" "mgmt_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hub.name
  network_security_group_name = azurerm_network_security_group.management.name
}

resource "azurerm_network_security_rule" "mgmt_allow_bastion" {
  name                        = "allow-bastion-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = var.hub_bastion_subnet_prefix
  destination_address_prefix  = var.hub_management_subnet_prefix
  resource_group_name         = azurerm_resource_group.hub.name
  network_security_group_name = azurerm_network_security_group.management.name
}

resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}
