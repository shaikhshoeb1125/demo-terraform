resource_group_name     = "pterra-rg-dev"
resource_group_location = "Central India"
virtual_network_name    = "pterra-vnet"
vnet_address_space = "10.0.0.0/22"

pterra-subnets = {
  fe-subnet = {
    name             = "pterra-fe-subnet"
    address_prefixes = "10.0.0.0/26"
  }
  be-subnet = {
    name             = "pterra-be-subnet"
    address_prefixes = "10.0.0.64/26"
  }
}