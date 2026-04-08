variable "resource_group_name" {
  description = "Name of Resource Group"
  type        = string
  default     = "rg-vnet-tutorial"
}

variable "vnets" {
  description = "Map of VNets"
  type = map(object({
    location      = string
    address_space = list(string)
  }))

  default = {
    vnet-frontend = {
      location      = "Central India"
      address_space = ["10.10.0.0/16"]
    }
    vnet-backend = {
      location      = "West India"
      address_space = ["10.20.0.0/16"]
    }
  }
}

variable "subnets" {
  description = "Map of Subnets mapped to VNets"
  type = map(object({
    vnet_name      = string
    address_prefix = string
  }))

  default = {
    snet-web = {
      vnet_name      = "vnet-frontend"
      address_prefix = "10.10.1.0/24"
    }
    snet-app = {
      vnet_name      = "vnet-frontend"
      address_prefix = "10.10.2.0/24"
    }
    snet-api = {
      vnet_name      = "vnet-backend"
      address_prefix = "10.20.1.0/24"
    }
    snet-db = {
      vnet_name      = "vnet-backend"
      address_prefix = "10.20.2.0/24"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = "Central India"
}

resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  name                = each.key
  location            = each.value.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = each.value.address_space
  tags = {
    managed_by = "terraform"
    vnet       = each.key
  }
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[each.value.vnet_name].name
  address_prefixes     = [each.value.address_prefix]
}

output "vnet_names" {
  value = [
    for v in azurerm_virtual_network.this : v.name
  ]
}

output "subnet_ids" {
  value = { for k,v in azurerm_subnet.this : k => v.id}
}

