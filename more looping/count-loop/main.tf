################################### Resource Group ###################################
resource "azurerm_resource_group" "countrg2" {
  name     = "count-rg2"
  location = "Central India"
}

################################### Storage Account ###################################
resource "azurerm_storage_account" "sa" {
  count                    = length(var.storagenames)
  name                     = "test2storage${var.storagenames[count.index]}"
  location                 = var.storage-locations[count.index]
  resource_group_name      = azurerm_resource_group.countrg2.name
  access_tier              = "Hot"
  account_replication_type = "LRS"
  account_tier             = "Standard"
}


################################### Virtual Network & Subnets ###################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = azurerm_resource_group.countrg2.location
  address_space       = ["10.0.0.0/20"]
  resource_group_name = azurerm_resource_group.countrg2.name
}

resource "azurerm_subnet" "subnets" {
  count                = 2
  name                 = "${var.subnetnames[count.index]}-snet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.countrg2.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
}

################################### NIC and VMs ###################################
resource "azurerm_network_interface" "nics" {
  depends_on = [ azurerm_public_ip.pips ]
  count               = 2
  name                = "nic-${count.index + 1}"
  location            = azurerm_resource_group.countrg2.location
  resource_group_name = azurerm_resource_group.countrg2.name

  ip_configuration {
    name                          = "internal-${count.index + 1}"
    subnet_id                     = azurerm_subnet.subnets[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pips[count.index].id
  }
}

resource "azurerm_public_ip" "pips" {
  count               = 2
  name                = "nic-${count.index + 1}"
  allocation_method   = "Static"
  location            = azurerm_resource_group.countrg2.location
  resource_group_name = azurerm_resource_group.countrg2.name
}

resource "azurerm_linux_virtual_machine" "example" {
  count               = 2
  name                = "vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.countrg2.name
  location            = azurerm_resource_group.countrg2.location
  size                = "Standard_B1s"
  admin_username      = "adminuser${count.index + 1}"
  network_interface_ids = [
    azurerm_network_interface.nics[count.index].id,
  ]
  disable_password_authentication = false
  admin_password                  = "Nierdre12345${count.index}"


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

# ################################### NSG & ASSOCIATION ###################################
resource "azurerm_network_security_group" "nsgs" {
  count               = 2
  name                = var.nsgnames[count.index]
  resource_group_name = azurerm_resource_group.countrg2.name
  location            = azurerm_resource_group.countrg2.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-snet-assoc" {
  count                     = 2
  network_security_group_id = azurerm_network_security_group.nsgs[count.index].id
  subnet_id                 = azurerm_subnet.subnets[count.index].id
}