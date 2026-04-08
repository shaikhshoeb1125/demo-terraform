resource "azurerm_resource_group" "pterra-rg-01" {
  name     = "rg-${var.appname}-${var.environement}-${var.index}"
  location = var.rg-location
}