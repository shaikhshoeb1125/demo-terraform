<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.47.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.47.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_interface.pterra-nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.pterra-nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.pterra-pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.pterra-subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_machine.pterra-vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) | resource |
| [azurerm_virtual_network.pterra-vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_key_vault.devopspt-keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.vm-admin-password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_resource_group.manually-created-rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_delete-datadisk"></a> [delete-datadisk](#input\_delete-datadisk) | n/a | `bool` | `true` | no |
| <a name="input_delete-osdisk"></a> [delete-osdisk](#input\_delete-osdisk) | n/a | `bool` | `true` | no |
| <a name="input_disk-size"></a> [disk-size](#input\_disk-size) | Size of the disk | `number` | `30` | no |
| <a name="input_pterra-vms"></a> [pterra-vms](#input\_pterra-vms) | Information/values about multiple vms | <pre>map(object({<br/>    name           = string<br/>    admin_username = string<br/>    vm_size        = string<br/>  }))</pre> | n/a | yes |
| <a name="input_subnet-address-space"></a> [subnet-address-space](#input\_subnet-address-space) | Address Space for subnet | `string` | `"10.0.0.0/26"` | no |
| <a name="input_vm-name"></a> [vm-name](#input\_vm-name) | n/a | `string` | `"pterra-vm01"` | no |
| <a name="input_vnet-address-space"></a> [vnet-address-space](#input\_vnet-address-space) | Address Space for Vnet | `string` | `"10.0.0.0/22"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->