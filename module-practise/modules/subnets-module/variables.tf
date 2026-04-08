variable "pterra-subnets" {
  type = map(object({
    name             = string
    address_prefixes = string
  }))
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}


variable "virtual_network_name" {
  type = string
}