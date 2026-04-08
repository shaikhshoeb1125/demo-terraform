variable "appname" {
  type = string
}

variable "env" {
  type = string
}

locals {
  a = 1
  b = 2
  c = 3
}

output "result" {
  value = local.a == local.b ? "its correct" : "its incorrect"
}
