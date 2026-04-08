# =============================================================
# REAL-WORLD USE CASE 2 – Multi-region infrastructure rollout
# =============================================================
# Problem: You need identical infra in 3 Azure regions for
# high availability, but typing out each region manually is
# error-prone and hard to maintain.
#
# Solution: for_each over a set of regions.  cidrsubnet() is
# used to carve out a non-overlapping CIDR per region.

variable "regions" {
  description = "Target Azure regions and their VNet CIDR offsets."
  type = map(object({
    cidr_offset = number # Used with cidrsubnet to get a unique /16
  }))
  default = {
    "eastus"        = { cidr_offset = 0 }
    "westeurope"    = { cidr_offset = 1 }
    "southeastasia" = { cidr_offset = 2 }
  }
}

variable "base_cidr" {
  description = "Master supernet from which per-region CIDRs are carved."
  type        = string
  default     = "10.0.0.0/8"
}

locals {
  # 10.0.0.0/8 + offset 0 → 10.0.0.0/16
  # 10.0.0.0/8 + offset 1 → 10.1.0.0/16
  region_cidrs = {
    for region, cfg in var.regions :
    region => cidrsubnet(var.base_cidr, 8, cfg.cidr_offset)
  }
}

resource "azurerm_resource_group" "region" {
  for_each = var.regions

  name     = "rg-platform-${each.key}"
  location = each.key
  tags     = { region = each.key, managed_by = "terraform" }
}

resource "azurerm_virtual_network" "region" {
  for_each = var.regions

  name                = "vnet-platform-${each.key}"
  location            = each.key
  resource_group_name = azurerm_resource_group.region[each.key].name
  address_space       = [local.region_cidrs[each.key]]

  tags = { region = each.key }
}

output "region_vnet_cidrs" {
  description = "CIDR allocated to each region's VNet."
  value       = local.region_cidrs
}
