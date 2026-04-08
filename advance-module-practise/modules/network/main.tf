resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.appname}-${var.environment}"
  resource_group_name = var.rg-name
  location            = var.rg-location
  address_space       = [var.vnet-space]
}

locals {
  bastion = cidrsubnet(var.vnet-space, 4, 0)
  fe-snet = cidrsubnet(var.vnet-space, 2, 1)
  be-snet = cidrsubnet(var.vnet-space, 2, 2)
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets-details
  
  name                 = each.value.name
  resource_group_name  = var.rg-name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet-space, each.value.new_bits, each.value.index)]
}


data "http" "my-ip-v4" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_network_security_group" "pterra-nsg" {
  name                = "nsg-${var.appname}-${var.environment}"
  location            = var.rg-location
  resource_group_name = var.rg-name

  security_rule {
    name                       = "AllowSSHFromMyIP"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = chomp(data.http.my-ip-v4.body)
    destination_address_prefix = "*"
  }
}
