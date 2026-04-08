# =============================================================
# Child Module: modules/network
# Resources: Resource Group + VNet + NSG + Subnets
# =============================================================

# ── Variables ────────────────────────────────────────────────

variable "env_name" {
  description = "Environment label (dev / prod / …)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "Base CIDR for the VNet."
  type        = string
}

variable "subnets" {
  description = "Ordered list of subnet definitions."
  type = list(object({
    name    = string
    newbits = number
    netnum  = number
  }))
}

# ── Resources ────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.env_name}"
  location = var.location

  tags = { environment = var.env_name, managed_by = "terraform" }
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.env_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = { environment = var.env_name }
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.env_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.address_space]

  tags = { environment = var.env_name, managed_by = "terraform" }
}

# Derive subnet CIDRs using cidrsubnet() function.
# cidrsubnet("10.10.0.0/16", 8, 1) → "10.10.1.0/24"
locals {
  subnet_map = {
    for s in var.subnets :
    s.name => {
      address_prefix = cidrsubnet(var.address_space, s.newbits, s.netnum)
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each = local.subnet_map

  name                 = "snet-${each.key}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = azurerm_subnet.this

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# ── Outputs ───────────────────────────────────────────────────

output "vnet_id" {
  description = "The VNet resource ID."
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Map of subnet name → ID."
  value = {
    for k, v in azurerm_subnet.this : k => v.id
  }
}

output "nsg_id" {
  description = "The NSG resource ID."
  value       = azurerm_network_security_group.this.id
}
