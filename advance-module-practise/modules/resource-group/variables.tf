variable "appname" {
  type = string
}

variable "environement" {
  type = string
}

variable "index" {
  type = number
}

variable "rg-location" {
  type = string
  validation {
    condition     = contains(["Central India", "South India"], var.rg-location)
    error_message = "Region Should be Central India or South India"
  }
}