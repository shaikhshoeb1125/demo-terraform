resource "azurerm_subnet" "pterra-subnets" {
  for_each = var.pterra-subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [each.value.address_prefixes]
}

resource "azurerm_network_security_group" "pterra-nsg" {
  name                = "pterra-nsg"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  security_rule {
    name                       = "DenyAll"
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

resource "azurerm_subnet_network_security_group_association" "pterra-nsg-azurerm-association" {
  for_each = azurerm_subnet.pterra-subnets

  network_security_group_id = azurerm_network_security_group.pterra-nsg.id
  subnet_id                 = each.value.id
}