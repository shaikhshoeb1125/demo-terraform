resource "azurerm_virtual_network" "pterra-network" {
  name                = "pterra-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
}

resource "azurerm_subnet" "pterra-subnet" {
  depends_on = [ azurerm_virtual_network.pterra-network, ]
  name                 = "pterra-subnet"
  resource_group_name  = data.azurerm_resource_group.manually-created-rg.name
  virtual_network_name = azurerm_virtual_network.pterra-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "pterra-nic" {
  name                = "pterra-nic"
  location            = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name

  ip_configuration {
    name                          = "pterra-configuration"
    subnet_id                     = azurerm_subnet.pterra-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "pterra-vm"
  location              = data.azurerm_resource_group.manually-created-rg.location
  resource_group_name   = data.azurerm_resource_group.manually-created-rg.name
  network_interface_ids = [azurerm_network_interface.pterra-nic.id]
  vm_size               = "Standard_B1s"


  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "pterrauser"
    admin_password = data.azurerm_key_vault_secret.pterra-secret.value
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}