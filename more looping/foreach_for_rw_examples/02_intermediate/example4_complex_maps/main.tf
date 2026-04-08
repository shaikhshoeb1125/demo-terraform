# =============================================================
# EXAMPLE 4 – Linux VMs via complex map(object) variables
# Level: Intermediate
# Concept: Deeply nested objects, optional() with defaults
#          (Terraform 1.3+)
# =============================================================

# ── Variables ────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Shared resource group."
  type        = string
  default     = "rg-vm-tutorial"
}

variable "location" {
  description = "Default Azure region."
  type        = string
  default     = "East US"
}

variable "virtual_machines" {
  description = <<-DESC
    Map of VM name → detailed configuration.
  DESC

  type = map(object({
    size           = string
    admin_username = string

    # optional() means the caller can omit this field; Terraform uses the default.
    os_disk = optional(object({
      caching              = string
      storage_account_type = string
      }), {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    })

    tags = optional(map(string), {})
  }))

  default = {
    "vm-frontend" = {
      size           = "Standard_D2s_v3"
      admin_username = "azureuser"
      # Notice we omitted os_disk - defaults applied automatically!
    }
    "vm-backend" = {
      size           = "Standard_D2s_v3"
      admin_username = "adminuser"
      os_disk = {
        caching              = "ReadOnly"
        storage_account_type = "Premium_LRS"
      }
      tags = { critical = "true" }
    }
  }
}

# ── Resources ────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

# We need a VNet and Subnet to place the VMs
resource "azurerm_virtual_network" "this" {
  name                = "vnet-vms"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-vms"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "this" {
  for_each = var.virtual_machines

  name                = "nic-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.virtual_machines

  name                            = each.key
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = file("~/.ssh/id_rsa.pub") # Assumes existence for tutorial purposes
  }

  network_interface_ids = [
    azurerm_network_interface.this[each.key].id,
  ]

  # Target the optional map object structure
  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = merge({ managed_by = "terraform" }, each.value.tags)
}

# ── Outputs ───────────────────────────────────────────────────

output "vm_private_ips" {
  description = "Private IPs of the deployed VMs."
  value = {
    for k, v in azurerm_network_interface.this :
    k => v.private_ip_address
  }
}
