resource "azurerm_virtual_network" "pterra-vnet" {
  name                = "pterra-vnet"
  address_space       = [var.vnet-address-space]
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
}

resource "azurerm_subnet" "pterra-subnet" {
  name                 = "pterra-subnet"
  resource_group_name  = data.azurerm_resource_group.manually-created-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-vnet.name
  address_prefixes     = [var.subnet-address-space]
}

resource "azurerm_public_ip" "pterra-pip" {
  for_each = var.pterra-vms

  name                = "${each.value.name}-pip"
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "pterra-nic" {
  for_each = var.pterra-vms

  name                = "${each.value.name}-nic"
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name

  ip_configuration {
    name                          = "${each.value.name}-ipconf"
    subnet_id                     = azurerm_subnet.pterra-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pterra-pip[each.key].id
  }
}

resource "azurerm_virtual_machine" "pterra-vm" {
  for_each = var.pterra-vms

  name                  = each.value.name
  location              = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name   = data.azurerm_resource_group.manually-created-rg.name
  network_interface_ids = [ azurerm_network_interface.pterra-nic[each.key].id ]
  vm_size               = each.value.vm_size

  delete_os_disk_on_termination    = var.delete-osdisk
  delete_data_disks_on_termination = var.delete-datadisk

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${each.value.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = var.disk-size
  }
  os_profile {
    computer_name  = each.value.name
    admin_username = each.value.admin_username
    admin_password = data.azurerm_key_vault_secret.vm-admin-password.value
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment     = "dev"
    deployment_time = timestamp()
  }
}

resource "azurerm_network_security_group" "pterra-nsg" {
  name                = "pterra-nsg"
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
  location            = data.azurerm_resource_group.manually-created-rg.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}