module "dev-rg" {
  source       = "./modules/resource-group"
  appname      = "pterra"
  environement = "dev"
  index        = "01"
  rg-location  = "Central India"
}

module "dev-network" {
  source      = "./modules/network"
  vnet-space  = "10.0.0.0/22"
  appname     = "pterra"
  environment = "dev"
  rg-name     = module.dev-rg.rg-details.name
  rg-location = module.dev-rg.rg-details.location
  subnets-details = {
    "bastion-snet" = {
      name     = "AzureBastionSubnet"
      new_bits = 4
      index    = 0
    }
    "fe-snet" = {
      name     = "fe-snet"
      new_bits = 2
      index    = 1
    }
    "be-snet" = {
      name     = "be-snet"
      new_bits = 2
      index    = 2
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "snets-association" {
  for_each = module.dev-network.subnet-details
  depends_on = [ module.dev-network, module.dev-rg ]

  subnet_id                 = each.value
  network_security_group_id = module.dev-network.nsg-details.id
}