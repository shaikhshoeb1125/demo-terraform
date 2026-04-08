################################### Resource Group ###################################
resource "azurerm_resource_group" "foreach-rg" {
  name     = "foreach-rg"
  location = "Australia East"
}

################################### Storage Account ###################################
resource "azurerm_storage_account" "sa" {
  for_each = var.storageaccounts

  name                     = "test2storage${each.value.name}"
  location                 = each.value.location
  resource_group_name      = azurerm_resource_group.foreach-rg.name
  access_tier              = "Hot"
  account_replication_type = each.value.account_replication_type
  account_tier             = "Standard"
}


################################### Virtual Network & Subnets ###################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = azurerm_resource_group.foreach-rg.location
  address_space       = ["10.0.0.0/20"]
  resource_group_name = azurerm_resource_group.foreach-rg.name
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.value.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.foreach-rg.name
  address_prefixes     = [each.value.address_prefixes]
}

################################### NIC and VMs ###################################
resource "azurerm_public_ip" "pips" {
  for_each = var.vmConfigs

  name                = "${each.value.name}-pip"
  allocation_method   = "Static"
  location            = azurerm_resource_group.foreach-rg.location
  resource_group_name = azurerm_resource_group.foreach-rg.name
}

resource "azurerm_network_interface" "nics" {
  depends_on = [azurerm_public_ip.pips]
  for_each   = var.vmConfigs

  name                = "${each.value.name}-nic"
  location            = azurerm_resource_group.foreach-rg.location
  resource_group_name = azurerm_resource_group.foreach-rg.name

  ip_configuration {
    name                          = "${each.value.name}-ipconf"
    subnet_id                     = azurerm_subnet.subnets[each.value.subnet].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pips[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  for_each = var.vmConfigs

  name                = each.value.name
  resource_group_name = azurerm_resource_group.foreach-rg.name
  location            = azurerm_resource_group.foreach-rg.location
  size                = each.value.size
  admin_username      = each.value.admin_username
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
# resource "azurerm_network_security_group" "nsgs" {
#   for_each            = var.subnets
#   name                = "${each.value.name}-nsg"
#   resource_group_name = azurerm_resource_group.foreach-rg.name
#   location            = azurerm_resource_group.foreach-rg.location

#   security_rule {
#     name                       = "AllowSSH"
#     priority                   = 4095
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "nsg-snet-assoc" {
#   for_each                  = var.subnets
#   network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
#   subnet_id                 = azurerm_subnet.subnets[each.key].id
# }