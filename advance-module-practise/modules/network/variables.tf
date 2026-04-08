variable "vnet-space" {
  type = string
}

variable "appname" {
  type = string
}

variable "environment" {
  type = string
}

variable "rg-name" {
  type = string
}

variable "rg-location" {
  type = string
}


variable "subnets-details" {
  type = map(object({
    name     = string
    new_bits = number
    index    = number
  }))
}