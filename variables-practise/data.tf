data "azurerm_resource_group" "manually-created-rg" {
  name = "manually-created-rg"
}

data "azurerm_key_vault" "devopspt-keyvault" {
  resource_group_name = "manually-created-rg"
  name                = "devopspt-keyvault"
}

data "azurerm_key_vault_secret" "vm-admin-password" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.devopspt-keyvault.id
}

