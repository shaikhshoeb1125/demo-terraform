# Example Terraform Variables File
# Copy this file to terraform.tfvars and customize the values

# Basic Configuration
prefix   = "pazure"
location = "Central India"

# Environments to deploy (default: dev, uat, prod)
environments = ["dev", "uat", "prod"]

# Network Configuration for Hub
hub_vnet_address_space       = "10.0.0.0/16"
hub_firewall_subnet_prefix   = "10.0.1.0/26"
hub_bastion_subnet_prefix    = "10.0.2.0/26"
hub_gateway_subnet_prefix    = "10.0.3.0/27"
hub_management_subnet_prefix = "10.0.4.0/24"

# Spoke VNet Address Spaces (default values shown)
# spoke_vnet_address_spaces = {
#   dev = {
#     vnet_cidr       = "10.1.0.0/16"
#     web_subnet_cidr = "10.1.1.0/24"
#     app_subnet_cidr = "10.1.2.0/24"
#     db_subnet_cidr  = "10.1.3.0/24"
#   }
#   uat = {
#     vnet_cidr       = "10.2.0.0/16"
#     web_subnet_cidr = "10.2.1.0/24"
#     app_subnet_cidr = "10.2.2.0/24"
#     db_subnet_cidr  = "10.2.3.0/24"
#   }
#   prod = {
#     vnet_cidr       = "10.3.0.0/16"
#     web_subnet_cidr = "10.3.1.0/24"
#     app_subnet_cidr = "10.3.2.0/24"
#     db_subnet_cidr  = "10.3.3.0/24"
#   }
# }

# Azure Firewall Configuration
firewall_sku_tier = "Standard" # Options: Standard, Premium

# Azure Bastion Configuration
bastion_sku = "Standard" # Options: Basic, Standard, Premium

# Virtual Machine Sizing by Environment
# Defaults are optimized for cost/performance by environment
# vm_sizes = {
#   dev = {
#     web = "Standard_B2s"
#     app = "Standard_B2s"
#     db  = "Standard_B2ms"
#   }
#   uat = {
#     web = "Standard_D2s_v5"
#     app = "Standard_D2s_v5"
#     db  = "Standard_E2s_v5"
#   }
#   prod = {
#     web = "Standard_D4s_v5"
#     app = "Standard_D4s_v5"
#     db  = "Standard_E4s_v5"
#   }
# }

# VM Authentication
admin_username = "azureadmin"

# REQUIRED: Add your SSH public key here
# Generate with: ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Then get the public key: cat ~/.ssh/id_rsa.pub
admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3SHNYvEADcjH5uhT5C9GBbhJAQVZIp0XP90K9NiLVGZqgHENPebX6X9Gm2FPOy266qoaJBpoaJZYc+NztUpoG/a7+MNP+KrjNI+ect8m7liQbbCQyFXYRksBK+AriizL2L+cUMQkTsy0fOxz4iidsbWC9XLW9fc6q3h3vV4VWGWm4bzl9GOTR5yZ7qM4ATnNiE1/Dy0tkZ9c25q/Bq3y2zXrR1waMDbi5i28aVnU4IfaKfpKTDzzJlM2VIDAEyrZhPQ3a0qMw6Me1jvDap9GRHhi40F+4T6IEYU6naQHre9RvADjF3zOMagm6Wtlv1wnxRj4hgIyCt0YeCvIJWwRuaT9Fk086TkuiGBZv+JyPD6G9eu/pKAeKpt/0LolaELj0Ly47vcueF4IO2/5w7fnNM0Cxd/rNjk5M/WWk5ZEiVZ4JRBf4BEAjKyt+VnMQHLeHj9NreNjrGn1YRnj48dge8okEwq7mGsFJMcNVf7wChUZD5FnUkkZwXy38aYjjld9C2d+v9xt0Q1WQvOCGjH2RC2pFE8q3GR1WUuP2ezVHD3CJXP2cFXHtD5+kUYha/uyIAOreNP9BWiMIYSkJbJZtKjTJmqEa7ath44Req2NPz68FyWYZxbylAtlyGMoTBAcmHj5jPaK7VRgymkC7DURsrbqShq5IdbNNvilDugpQXQ== shoebshaikh@macbookpro"

# High Availability Configuration
availability_zones = ["1", "2", "3"]

# Feature Flags
deploy_vms            = true # Set to false to skip VM deployment
deploy_gateway_subnet = true # Set to false to skip Gateway Subnet

# Additional Tags
tags = {
  Project    = "Hub-and-Spoke-Network"
  Owner      = "Infrastructure-Team"
  Department = "IT"
  CostCenter = "12345"
}
