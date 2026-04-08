variable "pterra-vms" {
  description = "Information/values about multiple vms"
  type = map(object({
    name           = string
    admin_username = string
    vm_size        = string
  }))
}

variable "vnet-address-space" {
  description = "Address Space for Vnet"
  type        = string
  default     = "10.0.0.0/22"
}

variable "subnet-address-space" {
  description = "Address Space for subnet"
  type        = string
  default     = "10.0.0.0/26"
}

variable "delete-osdisk" {
  type    = bool
  default = true
}

variable "delete-datadisk" {
  type    = bool
  default = true
}

variable "disk-size" {
  description = "Size of the disk"
  type        = number
  default     = 30
}

variable "vm-name" {
  type    = string
  default = "pterra-vm01"
}