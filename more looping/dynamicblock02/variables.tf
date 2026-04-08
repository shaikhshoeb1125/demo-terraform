variable "nsg-rules" {
  type = map(object({
    name     = string
    port     = number
    source   = string
    priority = number
  }))

  default = {
    "ssh" = {
      name     = "ssh"
      port     = "22"
      source   = "10.0.0.0/22"
      priority = "4094"
    }
    "http" = {
      name     = "http"
      port     = "80"
      source   = "0.0.0.0/0"
      priority = "4093"
    }
    "https" = {
      name     = "https"
      port     = "443"
      source   = "0.0.0.0/0"
      priority = "4092"
    }
  }
}

