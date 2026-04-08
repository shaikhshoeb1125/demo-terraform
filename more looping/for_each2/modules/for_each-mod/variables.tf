variable "rg-location" {
  type = string
}

variable "sa-configs" {
  type = map(object({
    name                     = string
    account_replication_type = string
  }))
}

variable "subnet-configs" {
  type = map(object({
    name = string
    address_prefixes = string
  }))
}


variable "vm-configs" {
  type = map(object({
      name           = string
      size           = string
      admin_password = string
      subnet         = string
  }))
} 

variable "nsg-configs" {
  type = map(object({
      name           = string
      port           = string
      priority       = string
      source         = string
  }))
}
