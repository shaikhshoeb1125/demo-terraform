
output "nsg-details" {
  value = azurerm_network_security_group.pterra-nsg
}

output "subnet-details" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}