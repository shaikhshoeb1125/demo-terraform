resource "azurerm_resource_group" "pterra-rg" {
  name     = "rg-${var.appname}-${var.env}"
  location = "Central India"
}

resource "azurerm_virtual_network" "pterra-vnet01" {
  name                = "vnet-${var.appname}-${var.env}"
  resource_group_name = azurerm_resource_group.pterra-rg.name
  location            = azurerm_resource_group.pterra-rg.location
  address_space       = ["10.0.0.0/22"]
}


resource "azurerm_subnet" "subnets" {
  count                = 3
  name                 = "snet-${var.appname}-${var.env}-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.pterra-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-vnet01.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
}

resource "azurerm_public_ip" "pterra-public-ip" {
  count               = var.env == "Prod" ? 0 : 3
  name                = "pip-${var.appname}-${var.env}-${count.index + 1}"
  location            = azurerm_resource_group.pterra-rg.location
  resource_group_name = azurerm_resource_group.pterra-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "pterra-nic" {
  count               = var.env == "Prod" ? 0 : 3
  name                = "nic-${var.appname}-${var.env}-${count.index + 1}"
  location            = azurerm_resource_group.pterra-rg.location
  resource_group_name = azurerm_resource_group.pterra-rg.name

  ip_configuration {
    name                          = "ipconf-${count.index + 1}"
    subnet_id                     = azurerm_subnet.subnets[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pterra-public-ip[count.index].id
  }
}


resource "azurerm_virtual_machine" "pterra-vms" {
  count                            = var.env == "Prod" ? 0 : 3
  name                             = "vm-${var.appname}-${var.env}-${count.index + 1}"
  location                         = azurerm_resource_group.pterra-rg.location
  resource_group_name              = azurerm_resource_group.pterra-rg.name
  network_interface_ids            = [azurerm_network_interface.pterra-nic[count.index].id]
  vm_size                          = "Standard_B1s"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "pterra-vm-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "pterra-vm-${count.index + 1}"
    admin_username = "azureuser${count.index + 1}"
    admin_password = "Password@12345"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
    severity    = var.env == "Prod" ? "High" : "Low"
  }
}
