data "azurerm_resource_group" "manually-created-rg" {
  name = "manually-created-rg"
}

data "azurerm_key_vault" "devopspt-keyvault" {
  name                = "devopspt-keyvault"
  resource_group_name = data.azurerm_resource_group.manually-created-rg.name
}

data "azurerm_key_vault_secret" "pterra-secret" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.devopspt-keyvault.id
}