resource "azurerm_resource_group" "pterra-rg" {
  name     = "pterra-rg"
  location = "Central India"
}

resource "azurerm_virtual_network" "pterra-vnet" {
  name                = "pterra-vnet"
  location            = azurerm_resource_group.pterra-rg.location
  resource_group_name = azurerm_resource_group.pterra-rg.name
  address_space       = [var.vnet_space]
}

locals {
  subnet01 = cidrsubnet(var.vnet_space, 4, 0)
  subnet02 = cidrsubnet(var.vnet_space, 4, 1)
  subnet03 = cidrsubnet(var.vnet_space, 4, 2)
}


resource "azurerm_subnet" "pterra-fe-subnet" {
  name                 = "fe-subnet01"
  resource_group_name  = azurerm_resource_group.pterra-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-vnet.name
  address_prefixes     = [local.subnet01]
}

resource "azurerm_subnet" "pterra-be-subnets" {
  name                 = "be-subnet02"
  resource_group_name  = azurerm_resource_group.pterra-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-vnet.name
  address_prefixes     = [local.subnet02]
}

resource "azurerm_subnet" "pterra-db-subnets" {
  name                 = "db-subnet03"
  resource_group_name  = azurerm_resource_group.pterra-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-vnet.name
  address_prefixes     = [local.subnet03]
}

data "http" "myipv4" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_network_security_group" "pterra-nsg" {
  name                = "pterra-nsg"
  location            = azurerm_resource_group.pterra-rg.location
  resource_group_name = azurerm_resource_group.pterra-rg.name

  security_rule {
    name                       = "AllowSSHFromMyIP"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = chomp(data.http.myipv4.body)
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pterra-nsg-association" {
  subnet_id                 = azurerm_subnet.pterra-fe-subnet.id
  network_security_group_id = azurerm_network_security_group.pterra-nsg.id
}


resource "azurerm_public_ip" "pterra-pip" {
  name                = "pterra-pip"
  resource_group_name = azurerm_resource_group.pterra-rg.name
  location            = azurerm_resource_group.pterra-rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "pterra-nic" {
  name                = "pterra-nic"
  location            = azurerm_resource_group.pterra-rg.location
  resource_group_name = azurerm_resource_group.pterra-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pterra-fe-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pterra-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "pterra-vm01" {
  name                = "pterra-vm01"
  resource_group_name = azurerm_resource_group.pterra-rg.name
  location            = azurerm_resource_group.pterra-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.pterra-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

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

