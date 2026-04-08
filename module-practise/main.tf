resource "azurerm_resource_group" "pterra-rg-dev" {
  name     = "pterra-rg-dev"
  location = "Central India"
}

resource "azurerm_virtual_network" "pterra-vnet" {
  name                = "pterra-vnet"
  location            = azurerm_resource_group.pterra-rg-dev.location
  resource_group_name = azurerm_resource_group.pterra-rg-dev.name
  address_space       = [var.vnet_address_space]
}

module "subnets-dev" {
  source                  = "./modules/subnets-module"
  pterra-subnets          = var.pterra-subnets
  resource_group_name     = var.resource_group_name
  resource_group_location = var.resource_group_location
  virtual_network_name    = var.virtual_network_name

  depends_on = [azurerm_resource_group.pterra-rg-dev, azurerm_virtual_network.pterra-vnet ]
}

  
