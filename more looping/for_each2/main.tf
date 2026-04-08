module "for-each-module" {
  source      = "./modules/for_each-mod"
  
  rg-location = "Central India"
  nsg-configs = var.nsg-configs
  vm-configs = var.vm-configs
  sa-configs = var.sa-configs
  subnet-configs = var.subnet-configs
}