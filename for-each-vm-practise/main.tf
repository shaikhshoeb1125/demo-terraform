resource "azurerm_virtual_network" "pterra-vnet01" {
  name                = "pterra-vnet01"
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
  location            = data.azurerm_resource_group.manually-created-rg.location
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "pterra-subnet01" {
  name                 = "pterra-subnet01"
  resource_group_name  = data.azurerm_resource_group.manually-created-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-vnet01.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_public_ip" "pterra-public-ip" {
  for_each = var.vms

  name                = "${each.value.name}-pip"
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "pterra-nic" {
  for_each = var.vms

  name                = "${each.value.name}-nic"
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name

  ip_configuration {
    name                          = "${each.value.name}-ip-configuration"
    subnet_id                     = azurerm_subnet.pterra-subnet01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pterra-public-ip[each.key].id
  }
}


resource "azurerm_virtual_machine" "pterra-vms" {
  for_each = var.vms

  name                             = each.value.name
  location                         = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name              = data.azurerm_resource_group.manually-created-rg.name
  network_interface_ids            = [azurerm_network_interface.pterra-nic[each.key].id]
  vm_size                          = each.value.size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${each.value.name}-os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
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
    environment = "staging"
  }
}