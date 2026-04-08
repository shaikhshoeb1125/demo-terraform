resource "azurerm_resource_group" "rg2" {
  name     = "rg2"
  location = "Central India"
}

resource "azurerm_network_security_group" "pterra-nsg" {
  name                = "fe-snet-nsg"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name


  security_rule {
    name                       = "DenyAll"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.nsg-rules
    iterator = port
    content {
      name                       = "AllowPort-${port.value.port}"
      priority                   = port.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = port.value.port
      source_address_prefix      = port.value.source
      destination_address_prefix = "*"
    }
  }
}