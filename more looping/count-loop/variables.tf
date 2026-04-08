variable "storagenames" {
  type    = list(any)
  default = ["app001", "app002"]
}

variable "storage-locations" {
  type    = list(any)
  default = ["southindia", "centralindia"]
}

variable "subnetnames" {
  type    = list(any)
  default = ["fe", "be"]
}

variable "nsgnames" {
  type    = list(any)
  default = ["fe-nsg", "be-nsg"]
}

