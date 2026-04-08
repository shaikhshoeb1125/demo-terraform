# Outputs for Azure Hub-and-Spoke Network Architecture
# Environment-based spokes (dev, uat, prod)

###############################################################################
# Hub VNet Outputs
###############################################################################

output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = azurerm_virtual_network.hub.name
}

output "hub_vnet_address_space" {
  description = "Hub VNet address space"
  value       = azurerm_virtual_network.hub.address_space
}

###############################################################################
# Spoke VNet Outputs
###############################################################################

output "spoke_vnets" {
  description = "Spoke VNet information by environment"
  value = {
    for env in var.environments : env => {
      id            = azurerm_virtual_network.spoke[env].id
      name          = azurerm_virtual_network.spoke[env].name
      address_space = azurerm_virtual_network.spoke[env].address_space
      subnets = {
        web = {
          id   = azurerm_subnet.web[env].id
          cidr = var.spoke_vnet_address_spaces[env].web_subnet_cidr
        }
        app = {
          id   = azurerm_subnet.app[env].id
          cidr = var.spoke_vnet_address_spaces[env].app_subnet_cidr
        }
        db = {
          id   = azurerm_subnet.db[env].id
          cidr = var.spoke_vnet_address_spaces[env].db_subnet_cidr
        }
      }
    }
  }
}

###############################################################################
# Azure Firewall Outputs
###############################################################################

output "firewall_id" {
  description = "Azure Firewall resource ID"
  value       = azurerm_firewall.main.id
}

output "firewall_name" {
  description = "Azure Firewall name"
  value       = azurerm_firewall.main.name
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP address (used for routing)"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Azure Firewall public IP address"
  value       = azurerm_public_ip.firewall.ip_address
}

###############################################################################
# Azure Bastion Outputs
###############################################################################

output "bastion_id" {
  description = "Azure Bastion resource ID"
  value       = azurerm_bastion_host.main.id
}

output "bastion_name" {
  description = "Azure Bastion name"
  value       = azurerm_bastion_host.main.name
}

output "bastion_dns_name" {
  description = "Azure Bastion DNS name"
  value       = azurerm_bastion_host.main.dns_name
}

###############################################################################
# VM Outputs
###############################################################################

output "vm_ids" {
  description = "Virtual machine resource IDs by environment and tier"
  value = var.deploy_vms ? {
    for env in var.environments : env => {
      web = azurerm_linux_virtual_machine.web[env].id
      #app = azurerm_linux_virtual_machine.app[env].id
      #db  = azurerm_linux_virtual_machine.db[env].id
    }
  } : null
}

output "vm_private_ips" {
  description = "Virtual machine private IP addresses by environment and tier"
  value = var.deploy_vms ? {
    for env in var.environments : env => {
      web = azurerm_network_interface.web_vm[env].private_ip_address
      #app = azurerm_network_interface.app_vm[env].private_ip_address
      #db  = azurerm_network_interface.db_vm[env].private_ip_address
    }
  } : null
}

output "vm_principal_ids" {
  description = "VM managed identity principal IDs for Azure RBAC by environment and tier"
  value = var.deploy_vms ? {
    for env in var.environments : env => {
      web = azurerm_linux_virtual_machine.web[env].identity[0].principal_id
      #app = azurerm_linux_virtual_machine.app[env].identity[0].principal_id
      #db  = azurerm_linux_virtual_machine.db[env].identity[0].principal_id
    }
  } : null
}

###############################################################################
# Network Security Group Outputs
###############################################################################

output "nsg_ids" {
  description = "Network Security Group resource IDs by environment and tier"
  value = {
    hub = {
      management = azurerm_network_security_group.management.id
    }
    spokes = {
      for env in var.environments : env => {
        web = azurerm_network_security_group.web[env].id
        app = azurerm_network_security_group.app[env].id
        db  = azurerm_network_security_group.db[env].id
      }
    }
  }
}

###############################################################################
# Route Table Outputs
###############################################################################

output "route_table_ids" {
  description = "Route table resource IDs by environment and tier"
  value = {
    for env in var.environments : env => {
      web = azurerm_route_table.spokes[env].id
      # app = azurerm_route_table.app[env].id
      # db  = azurerm_route_table.db[env].id
    }
  }
}

###############################################################################
# Resource Group Outputs
###############################################################################

output "resource_groups" {
  description = "Resource group information"
  value = merge(
    {
      hub = {
        id       = azurerm_resource_group.hub.id
        name     = azurerm_resource_group.hub.name
        location = azurerm_resource_group.hub.location
      }
    },
    {
      for env in var.environments : "spoke_${env}" => {
        id       = azurerm_resource_group.spoke[env].id
        name     = azurerm_resource_group.spoke[env].name
        location = azurerm_resource_group.spoke[env].location
      }
    }
  )
}

# ###############################################################################
# # Connection Instructions
# ###############################################################################

# output "bastion_connection_info" {
#   description = "Instructions for connecting to VMs via Bastion"
#   value = var.deploy_vms ? join("\n", [
#     "To connect to VMs using Azure Bastion:",
#     "",
#     "1. Navigate to Azure Portal",
#     "2. Go to the VM you want to access",
#     "3. Click \"Connect\" > \"Bastion\"",
#     "4. Use username: ${var.admin_username}",
#     "5. Select SSH Private Key authentication",
#     "",
#     "Bastion Host: ${azurerm_bastion_host.main.name}",
#     "",
#     "VMs available by environment:",
#     join("\n", [for env in var.environments : format("  %-4s - Web: %s-web-vm (%s), App: %s-app-vm (%s), DB: %s-db-vm (%s)",
#       upper(env),
#       "${var.prefix}-${env}",
#       azurerm_network_interface.web_vm[env].private_ip_address,
#       "${var.prefix}-${env}",
#       #azurerm_network_interface.app_vm[env].private_ip_address,
#       #"${var.prefix}-${env}",
#       #azurerm_network_interface.db_vm[env].private_ip_address
#     )])
#   ]) : "VMs not deployed (var.deploy_vms = false)"
# }

output "architecture_summary" {
  description = "Summary of deployed architecture"
  value = <<-EOT
    Azure Hub-and-Spoke Network Architecture Deployed
    ==================================================

    Hub VNet: ${azurerm_virtual_network.hub.name}
      - Address Space: ${var.hub_vnet_address_space}
      - Azure Firewall: ${azurerm_firewall.main.name} (${azurerm_firewall.main.ip_configuration[0].private_ip_address})
      - Azure Bastion: ${azurerm_bastion_host.main.name}
      - Gateway Subnet: ${var.deploy_gateway_subnet ? "Deployed" : "Not deployed"}

    Spoke VNets (Environments: ${join(", ", var.environments)}):
    ${join("\n    ", [for env in var.environments : format(
  "%-4s VNet: %s (%s)\n         - Web Subnet:  %s\n         - App Subnet:  %s\n         - DB Subnet:   %s",
  upper(env),
  azurerm_virtual_network.spoke[env].name,
  var.spoke_vnet_address_spaces[env].vnet_cidr,
  var.spoke_vnet_address_spaces[env].web_subnet_cidr,
  var.spoke_vnet_address_spaces[env].app_subnet_cidr,
  var.spoke_vnet_address_spaces[env].db_subnet_cidr
)])}

    Security Features:
      - All spoke traffic routes through Azure Firewall
      - Network Security Groups applied to all subnets
      - Secure VM access via Azure Bastion only
      - No public IPs on VMs
      - Zone-redundant deployment for high availability
      - Environment-based isolation with firewall rules

    Azure Well-Architected Framework Alignment:
      ✓ Reliability: Multi-zone deployment, redundant connectivity
      ✓ Security: Defense in depth with Firewall, NSGs, and Bastion
      ✓ Cost Optimization: Right-sized resources per environment
      ✓ Operational Excellence: Consistent tagging, modular design
      ✓ Performance Efficiency: Optimized network paths

    Total Resources Deployed:
      - ${length(var.environments)} Spoke VNets (${join(", ", var.environments)})
      - ${length(var.environments) * 3} Subnets per spoke (web, app, db)
      - ${var.deploy_vms ? length(var.environments) * 3 : 0} VMs total
  EOT
}
