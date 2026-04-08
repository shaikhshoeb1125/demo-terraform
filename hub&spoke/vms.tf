# Example Virtual Machines in Spoke Networks
# One VM per tier (web, app, db) per environment (dev, uat, prod)
# Controlled by var.deploy_vms feature flag

###############################################################################
# WEB TIER VMS
###############################################################################

resource "azurerm_network_interface" "web_vm" {
  for_each = var.deploy_vms ? toset(var.environments) : []

  name                = "${var.prefix}-${each.key}-web-vm-nic"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  tags                = merge(local.common_tags, { environment = each.key, tier = "web" })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  for_each = var.deploy_vms ? toset(var.environments) : []

  name                            = "${var.prefix}-${each.key}-web-vm"
  location                        = azurerm_resource_group.spoke[each.key].location
  resource_group_name             = azurerm_resource_group.spoke[each.key].name
  size                            = var.vm_sizes[each.key].web
  admin_username                  = var.admin_username
  disable_password_authentication = true
  tags                            = merge(local.common_tags, { environment = each.key, tier = "web" })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }

  network_interface_ids = [
    azurerm_network_interface.web_vm[each.key].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "${var.prefix}-${each.key}-web-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.key == "prod" ? "Premium_LRS" : "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null # Uses managed storage account
  }

  # Azure Well-Architected Framework: Reliability
  # Deploy prod in zone 1, uat in zone 2, dev in zone 3
  #zone = each.key == "prod" ? var.availability_zones[0] : each.key == "uat" ? var.availability_zones[1] : var.availability_zones[2]

  identity {
    type = "SystemAssigned"
  }
}

# Install web server via custom script extension (example)
resource "azurerm_virtual_machine_extension" "web_init" {
  for_each = var.deploy_vms ? toset(var.environments) : []

  name                 = "web-init"
  virtual_machine_id   = azurerm_linux_virtual_machine.web[each.key].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  tags                 = merge(local.common_tags, { environment = each.key, tier = "web" })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }

  settings = jsonencode({
    commandToExecute = "apt-get update && apt-get install -y nginx && systemctl enable nginx && systemctl start nginx"
  })
}

# # ###############################################################################
# # # APP TIER VMS
# # ###############################################################################

# # resource "azurerm_network_interface" "app_vm" {
# #   for_each = var.deploy_vms ? toset(var.environments) : []

# #   name                = "${var.prefix}-${each.key}-app-vm-nic"
# #   location            = azurerm_resource_group.spoke[each.key].location
# #   resource_group_name = azurerm_resource_group.spoke[each.key].name
# #   tags                = merge(local.common_tags, { environment = each.key, tier = "app" })

# #   ip_configuration {
# #     name                          = "internal"
# #     subnet_id                     = azurerm_subnet.app[each.key].id
# #     private_ip_address_allocation = "Dynamic"
# #   }
# # }

# # resource "azurerm_linux_virtual_machine" "app" {
# #   for_each = var.deploy_vms ? toset(var.environments) : []

# #   name                            = "${var.prefix}-${each.key}-app-vm"
# #   location                        = azurerm_resource_group.spoke[each.key].location
# #   resource_group_name             = azurerm_resource_group.spoke[each.key].name
# #   size                            = var.vm_sizes[each.key].app
# #   admin_username                  = var.admin_username
# #   disable_password_authentication = true
# #   tags                            = merge(local.common_tags, { environment = each.key, tier = "app" })

# #   network_interface_ids = [
# #     azurerm_network_interface.app_vm[each.key].id,
# #   ]

# #   admin_ssh_key {
# #     username   = var.admin_username
# #     public_key = var.admin_ssh_public_key
# #   }

# #   os_disk {
# #     name                 = "${var.prefix}-${each.key}-app-vm-osdisk"
# #     caching              = "ReadWrite"
# #     storage_account_type = each.key == "prod" ? "Premium_LRS" : "StandardSSD_LRS"
# #   }

# #   source_image_reference {
# #     publisher = "Canonical"
# #     offer     = "0001-com-ubuntu-server-jammy"
# #     sku       = "22_04-lts-gen2"
# #     version   = "latest"
# #   }

# #   boot_diagnostics {
# #     storage_account_uri = null
# #   }

# # #  zone = each.key == "prod" ? var.availability_zones[0] : each.key == "uat" ? var.availability_zones[1] : var.availability_zones[2]

# #   identity {
# #     type = "SystemAssigned"
# #   }
# # }

# # ###############################################################################
# # # DB TIER VMS
# # ###############################################################################

# # resource "azurerm_network_interface" "db_vm" {
# #   for_each = var.deploy_vms ? toset(var.environments) : []

# #   name                = "${var.prefix}-${each.key}-db-vm-nic"
# #   location            = azurerm_resource_group.spoke[each.key].location
# #   resource_group_name = azurerm_resource_group.spoke[each.key].name
# #   tags                = merge(local.common_tags, { environment = each.key, tier = "db" })

# #   ip_configuration {
# #     name                          = "internal"
# #     subnet_id                     = azurerm_subnet.db[each.key].id
# #     private_ip_address_allocation = "Dynamic"
# #   }
# # }

# # resource "azurerm_linux_virtual_machine" "db" {
# #   for_each = var.deploy_vms ? toset(var.environments) : []

# #   name                            = "${var.prefix}-${each.key}-db-vm"
# #   location                        = azurerm_resource_group.spoke[each.key].location
# #   resource_group_name             = azurerm_resource_group.spoke[each.key].name
# #   size                            = var.vm_sizes[each.key].db
# #   admin_username                  = var.admin_username
# #   disable_password_authentication = true
# #   tags                            = merge(local.common_tags, { environment = each.key, tier = "db" })

# #   network_interface_ids = [
# #     azurerm_network_interface.db_vm[each.key].id,
# #   ]

# #   admin_ssh_key {
# #     username   = var.admin_username
# #     public_key = var.admin_ssh_public_key
# #   }

# #   os_disk {
# #     name                 = "${var.prefix}-${each.key}-db-vm-osdisk"
# #     caching              = "ReadWrite"
# #     storage_account_type = each.key == "prod" ? "Premium_LRS" : "StandardSSD_LRS"
# #     disk_size_gb         = 30
# #   }

# #   source_image_reference {
# #     publisher = "Canonical"
# #     offer     = "0001-com-ubuntu-server-jammy"
# #     sku       = "22_04-lts-gen2"
# #     version   = "latest"
# #   }

# #   boot_diagnostics {
# #     storage_account_uri = null
# #   }

# #   zone = each.key == "prod" ? var.availability_zones[0] : each.key == "uat" ? var.availability_zones[1] : var.availability_zones[2]

# #   identity {
# #     type = "SystemAssigned"
# #   }
# # }

# # # Data disk for database workloads (prod and uat only)
# # resource "azurerm_managed_disk" "db_data_disk" {
# #   for_each = var.deploy_vms ? toset([for env in var.environments : env if env != "dev"]) : []

# #   name                 = "${var.prefix}-${each.key}-db-vm-datadisk"
# #   location             = azurerm_resource_group.spoke[each.key].location
# #   resource_group_name  = azurerm_resource_group.spoke[each.key].name
# #   storage_account_type = each.key == "prod" ? "Premium_LRS" : "StandardSSD_LRS"
# #   create_option        = "Empty"
# #   disk_size_gb         = each.key == "prod" ? 1024 : 512
# # #  zone                 = each.key == "prod" ? var.availability_zones[0] : var.availability_zones[1]
# #   tags                 = merge(local.common_tags, { environment = each.key, tier = "db" })
# # }

# # resource "azurerm_virtual_machine_data_disk_attachment" "db_data_disk" {
# #   for_each = var.deploy_vms ? toset([for env in var.environments : env if env != "dev"]) : []

# #   managed_disk_id    = azurerm_managed_disk.db_data_disk[each.key].id
# #   virtual_machine_id = azurerm_linux_virtual_machine.db[each.key].id
# #   lun                = 0
# #   caching            = "ReadWrite"
# # }
