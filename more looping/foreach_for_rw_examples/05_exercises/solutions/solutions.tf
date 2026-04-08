# =============================================================
# EXERCISE SOLUTIONS
# =============================================================

# ─── Solution 1 ───────────────────────────────────────────────
variable "sol1_rgs" {
  type    = set(string)
  default = ["rg-sol-1", "rg-sol-2", "rg-sol-3"]
}
resource "azurerm_resource_group" "sol1" {
  for_each = var.sol1_rgs
  name     = each.key       # each.key == each.value for a set
  location = "East US"
}

# ─── Solution 2 ───────────────────────────────────────────────
variable "sol2_storage_map" {
  type = map(string)
  default = {
    "sasol2primary001" = "Standard_LRS"
    "sasol2bkp001"    = "Standard_GRS"
  }
}
resource "azurerm_resource_group" "sol2" {
  name     = "rg-sol2-storage"
  location = "East US"
}
resource "azurerm_storage_account" "sol2" {
  for_each                 = var.sol2_storage_map
  name                     = each.key
  resource_group_name      = azurerm_resource_group.sol2.name
  location                 = azurerm_resource_group.sol2.location
  account_tier             = "Standard"
  account_replication_type = each.value
}

# ─── Solution 3 ───────────────────────────────────────────────
variable "sol3_vnets" {
  type = map(object({
    location      = string
    address_space = string
    subnets       = map(string)
  }))
  default = {
    "vnet-sol-a" = {
      location      = "East US"
      address_space = "192.168.0.0/16"
      subnets = {
        "web"  = "192.168.1.0/24"
        "data" = "192.168.2.0/24"
      }
    }
  }
}
resource "azurerm_resource_group" "sol3" {
  name     = "rg-sol3-vnets"
  location = "East US"
}
resource "azurerm_virtual_network" "sol3" {
  for_each            = var.sol3_vnets
  name                = each.key
  location            = each.value.location
  resource_group_name = azurerm_resource_group.sol3.name
  address_space       = [each.value.address_space]
}
locals {
  sol3_subnets_flat = {
    for combo in flatten([
      for vnet_key, vnet_val in var.sol3_vnets : [
        for snet_name, cidr in vnet_val.subnets : {
          key      = "${vnet_key}/${snet_name}"
          vnet_key = vnet_key
          snet     = snet_name
          cidr     = cidr
        }
      ]
    ]) : combo.key => combo
  }
}
resource "azurerm_subnet" "sol3" {
  for_each             = local.sol3_subnets_flat
  name                 = each.value.snet
  resource_group_name  = azurerm_resource_group.sol3.name
  virtual_network_name = each.value.vnet_key
  address_prefixes     = [each.value.cidr]
  depends_on           = [azurerm_virtual_network.sol3]
}

# ─── Solution 4 ───────────────────────────────────────────────
variable "sol4_all_rgs" {
  type = map(object({
    location = string
    active   = bool
  }))
  default = {
    "rg-sol4-active-1" = { location = "East US",    active = true  }
    "rg-sol4-active-2" = { location = "West Europe", active = true  }
    "rg-sol4-disabled" = { location = "East US",    active = false }
  }
}
locals {
  sol4_active_rgs = {
    for k, v in var.sol4_all_rgs : k => v if v.active
  }
}
resource "azurerm_resource_group" "sol4" {
  for_each = local.sol4_active_rgs
  name     = each.key
  location = each.value.location
}
output "sol4_active_count" {
  value = length(local.sol4_active_rgs)
}

# ─── Solution 5 ───────────────────────────────────────────────
variable "sol5_tiers" {
  type = map(object({
    allowed_ports = list(number)
  }))
  default = {
    "web"  = { allowed_ports = [80, 443] }
    "api"  = { allowed_ports = [8080, 8443] }
    "data" = { allowed_ports = [5432] }
  }
}
resource "azurerm_resource_group" "sol5" {
  name     = "rg-sol5-nsg"
  location = "East US"
}
resource "azurerm_network_security_group" "sol5" {
  for_each            = var.sol5_tiers
  name                = "nsg-sol5-${each.key}"
  location            = azurerm_resource_group.sol5.location
  resource_group_name = azurerm_resource_group.sol5.name

  dynamic "security_rule" {
    for_each = each.value.allowed_ports
    content {
      name                       = "allow-port-${security_rule.value}"
      priority                   = 100 + security_rule.key  # key = list index
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value)
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}
