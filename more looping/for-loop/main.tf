variable "colors" {
  default = ["red", "green", "blue"]
}

variable "objectStorageConfigs" {
  default = {
    storage1 = {
      name = "test2storage0001"
      redundancy = "LRS"
      location = "South India"
    }
    storage2 = {
      name = "test2storage0002"
      redundancy = "LRS"
      location = "Central India"
    }
  }
}

output "output" {
  value = { for k,v in var.objectStorageConfigs : "sa-${k}" => v }
}