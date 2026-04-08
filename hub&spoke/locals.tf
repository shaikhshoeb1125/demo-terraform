# Local values for common configurations

locals {
  # Common tags applied to all resources following Azure Well-Architected Framework
  common_tags = merge(
    {
      ManagedBy    = "Terraform"
      Architecture = "Hub-and-Spoke"
      CostCenter   = "Infrastructure"
      CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
    },
    var.tags
  )

  # Network summary for documentation
  network_summary = {
    hub = {
      vnet_address_space = var.hub_vnet_address_space
      subnets = {
        firewall   = var.hub_firewall_subnet_prefix
        bastion    = var.hub_bastion_subnet_prefix
        gateway    = var.hub_gateway_subnet_prefix
        management = var.hub_management_subnet_prefix
      }
    }
    spokes = {
      for env in var.environments : env => {
        vnet_cidr       = var.spoke_vnet_address_spaces[env].vnet_cidr
        web_subnet_cidr = var.spoke_vnet_address_spaces[env].web_subnet_cidr
        app_subnet_cidr = var.spoke_vnet_address_spaces[env].app_subnet_cidr
        db_subnet_cidr  = var.spoke_vnet_address_spaces[env].db_subnet_cidr
      }
    }
  }
}
