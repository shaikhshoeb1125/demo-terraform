variable "vms" {
  type = map(object({
    name           = string
    size           = string
    admin_username = string
  }))
}



