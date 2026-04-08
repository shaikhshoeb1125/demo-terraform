sa-configs = {    
    "sa1" = {
      name                     = "test2storageaccount001"
      account_replication_type = "LRS"
    }
    "sa2" = {
      name                     = "test2storageaccount002"
      account_replication_type = "LRS"
    }
  }

subnet-configs = {
    fe-snet = {
      name             = "fe-snet"
      address_prefixes = "10.0.0.0/24"
    }
    be-snet = {
      name             = "be-snet"
      address_prefixes = "10.0.1.0/24"
    }
  }

vm-configs = {
    vm1 = {
      name           = "vm1"
      size           = "Standard_B1s"
      admin_password = "Nierdre12345"
      subnet         = "fe-snet"
    }
    vm2 = {
      name           = "vm2"
      size           = "Standard_B1s"
      admin_password = "Nierdre123456"
      subnet         = "be-snet"
    }
}   

nsg-configs = {
    ssh = {
      name     = "SSH-from-internal-network"
      port     = "22"
      priority = "4093"
      source   = "10.0.0.0/20"
    }
    http = {
      name     = "HTTP-from-Internet"
      port     = "80"
      priority = "4092"
      source   = "0.0.0.0/0"
    }
    https = {
      name     = "HTTPS-from-Internet"
      port     = "443"
      priority = "4091"
      source   = "0.0.0.0/0"
    }
  }