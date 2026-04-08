# Variables for Azure Hub-and-Spoke Network Architecture
# Environment-based spokes (dev, uat, prod) with web, app, and db subnets

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "pazure"

  validation {
    condition     = length(var.prefix) <= 6 && can(regex("^[a-z0-9]+$", var.prefix))
    error_message = "Prefix must be 6 characters or less and contain only lowercase letters and numbers."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central India"
}

variable "environments" {
  description = "List of environments to deploy"
  type        = list(string)
  default     = ["dev", "uat", "prod"]
}

###############################################################################
# Hub Network Configuration
###############################################################################

variable "hub_vnet_address_space" {
  description = "Address space for hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hub_firewall_subnet_prefix" {
  description = "Subnet prefix for Azure Firewall (minimum /26)"
  type        = string
  default     = "10.0.1.0/26"
}

variable "hub_bastion_subnet_prefix" {
  description = "Subnet prefix for Azure Bastion (minimum /26)"
  type        = string
  default     = "10.0.2.0/26"
}

variable "hub_gateway_subnet_prefix" {
  description = "Subnet prefix for VPN/ExpressRoute Gateway"
  type        = string
  default     = "10.0.3.0/27"
}

variable "hub_management_subnet_prefix" {
  description = "Subnet prefix for management resources"
  type        = string
  default     = "10.0.4.0/24"
}

###############################################################################
# Spoke Network Configuration
###############################################################################

variable "spoke_vnet_address_spaces" {
  description = "Address spaces for spoke VNets by environment"
  type = map(object({
    vnet_cidr       = string
    web_subnet_cidr = string
    app_subnet_cidr = string
    db_subnet_cidr  = string
  }))
  default = {
    dev = {
      vnet_cidr       = "10.1.0.0/16"
      web_subnet_cidr = "10.1.1.0/24"
      app_subnet_cidr = "10.1.2.0/24"
      db_subnet_cidr  = "10.1.3.0/24"
    }
    uat = {
      vnet_cidr       = "10.2.0.0/16"
      web_subnet_cidr = "10.2.1.0/24"
      app_subnet_cidr = "10.2.2.0/24"
      db_subnet_cidr  = "10.2.3.0/24"
    }
    prod = {
      vnet_cidr       = "10.3.0.0/16"
      web_subnet_cidr = "10.3.1.0/24"
      app_subnet_cidr = "10.3.2.0/24"
      db_subnet_cidr  = "10.3.3.0/24"
    }
  }
}

###############################################################################
# Azure Firewall Configuration
###############################################################################

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall SKU tier must be Standard or Premium."
  }
}

###############################################################################
# Azure Bastion Configuration
###############################################################################

variable "bastion_sku" {
  description = "Azure Bastion SKU (Basic, Standard, or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "Bastion SKU must be Basic, Standard, or Premium."
  }
}

###############################################################################
# Virtual Machine Configuration
###############################################################################

variable "vm_sizes" {
  description = "VM sizes by environment and tier"
  type = map(object({
    web = string
    app = string
    db  = string
  }))
  default = {
    dev = {
      web = "Standard_DC1ds_v3"
      app = "Standard_DC1ds_v3"
      db  = "Standard_DC1ds_v3"
    }
    uat = {
      web = "Standard_DC1ds_v3"
      app = "Standard_DC1ds_v3"
      db  = "Standard_DC1ds_v3"
    }
    prod = {
      web = "Standard_DC1ds_v3"
      app = "Standard_DC1ds_v3"
      db  = "Standard_DC1ds_v3"
    }
  }
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"

  validation {
    condition     = length(var.admin_username) >= 3 && length(var.admin_username) <= 32
    error_message = "Admin username must be between 3 and 32 characters."
  }
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-rsa |^ssh-ed25519 |^ecdsa-sha2-", var.admin_ssh_public_key))
    error_message = "Must be a valid SSH public key starting with ssh-rsa, ssh-ed25519, or ecdsa-sha2-."
  }
}

###############################################################################
# High Availability Configuration
###############################################################################

variable "availability_zones" {
  description = "Availability zones for high availability deployment"
  type        = list(string)
  default     = ["1", "2", "3"]

  validation {
    condition     = length(var.availability_zones) > 0 && length(var.availability_zones) <= 3
    error_message = "Must specify between 1 and 3 availability zones."
  }
}

###############################################################################
# Feature Flags
###############################################################################

variable "deploy_vms" {
  description = "Whether to deploy example VMs in each spoke"
  type        = bool
  default     = true
}

variable "deploy_gateway_subnet" {
  description = "Whether to deploy Gateway Subnet for VPN/ExpressRoute"
  type        = bool
  default     = true
}

###############################################################################
# Tags
###############################################################################

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
