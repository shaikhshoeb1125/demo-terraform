resource "azurerm_resource_group" "rg02" {
  name     = "rg02"
  location = var.rg-location
}

resource "azurerm_storage_account" "sa" {
  for_each                 = var.sa-configs
  name                     = each.value.name
  location                 = azurerm_resource_group.rg02.location
  resource_group_name      = azurerm_resource_group.rg02.name
  access_tier              = "Hot"
  account_replication_type = each.value.account_replication_type
  account_tier             = "Standard"
}

################################### Virtual Network & Subnets ###################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg02.location
  address_space       = ["10.0.0.0/20"]
  resource_group_name = azurerm_resource_group.rg02.name
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnet-configs
  name                 = each.value.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg02.name
  address_prefixes     = [each.value.address_prefixes]
}

################################### NIC and VMs ###################################
resource "azurerm_public_ip" "pips" {
  for_each            = var.vm-configs
  name                = "${each.value.name}-pip"
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg02.location
  resource_group_name = azurerm_resource_group.rg02.name
}

resource "azurerm_network_interface" "nics" {
  depends_on          = [azurerm_public_ip.pips]
  for_each            = var.vm-configs
  name                = "${each.value.name}-nic"
  location            = azurerm_resource_group.rg02.location
  resource_group_name = azurerm_resource_group.rg02.name

  ip_configuration {
    name                          = "${each.value.name}-internal"
    subnet_id                     = azurerm_subnet.subnets[each.value.subnet].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pips[each.key].id
  }
}



resource "azurerm_linux_virtual_machine" "example" {
  for_each            = var.vm-configs
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg02.name
  location            = azurerm_resource_group.rg02.location
  size                = each.value.size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nics[each.key].id,
  ]
  disable_password_authentication = false
  admin_password                  = each.value.admin_password


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

################################### NSG & ASSOCIATION ###################################
resource "azurerm_network_security_group" "nsgs" {
  for_each            = var.subnet-configs
  name                = "${each.value.name}-nsg"
  resource_group_name = azurerm_resource_group.rg02.name
  location            = azurerm_resource_group.rg02.location

  security_rule {
    name                       = "DenyAll"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.nsg-configs
    iterator = port
    content {
      name                       = "Allow-${port.value.name}"
      priority                   = port.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = port.value.port
      source_address_prefix      = port.value.source
      destination_address_prefix = "*"
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "nsg-snet-assoc" {
  for_each                  = var.subnet-configs
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
  subnet_id                 = azurerm_subnet.subnets[each.key].id
}