variable "storageaccounts" {
  type = map(object({
    name                     = string
    location                 = string
    account_replication_type = string
  }))
  default = {
    sa1 = {
      name                     = "sa00001"
      location                 = "Central India"
      account_replication_type = "LRS"
    }
    sa2 = {
      name                     = "sa00002"
      location                 = "South India"
      account_replication_type = "LRS"
    }
  }
}

variable "subnets" {
  type = map(object({
    name             = string
    address_prefixes = string
  }))
  default = {
    snet1 = {
      name             = "snet0001"
      address_prefixes = "10.0.0.0/24"
    }
    snet2 = {
      name             = "snet0002"
      address_prefixes = "10.0.1.0/24"
    }
  }
}

variable "vmConfigs" {
  type = map(object({
    name           = string
    admin_username = string
    admin_password = string
    size           = string
    subnet         = string
  }))
  default = {
    "vm1" = {
      name           = "vm1"
      admin_username = "vm1adminuser"
      admin_password = "Nierdre12345"
      size           = "Standard_D2s_v3"
      subnet         = "snet1"
    }
    "vm2" = {
      name           = "vm2"
      admin_username = "vm2adminuser"
      admin_password = "Nierdre12345"
      size           = "Standard_D2s_v3"
      subnet         = "snet2"
    }
  }
}