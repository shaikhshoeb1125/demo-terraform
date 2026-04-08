# =============================================================
# EXAMPLE 7 – for_each combined with dynamic blocks
# Level: Advanced
# Concept: dynamic{} blocks inside a for_each resource allow
#          a variable number of sub-blocks per resource instance.
# =============================================================
#
# REAL-WORLD PROBLEM:
# Each NSG may need a *different number* of security rules.
# Hard-coding ingress_security_rule blocks doesn't scale.
#
# PATTERN: dynamic block + for expression inside for_each
# ─────────────────────────────────────────────────────────
# The outer for_each creates one NSG per map entry.
# The inner dynamic block iterates over that entry's rules list.

# ── Variables ────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Resource group to hold all NSGs."
  type        = string
  default     = "rg-nsg-dynamic-tutorial"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "East US"
}

variable "network_security_groups" {
  description = <<-DESC
    Map of NSG name → list of security-rule objects.
    Rules are added via a dynamic block inside the NSG resource.
  DESC

  type = map(object({
    rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string # Inbound | Outbound
      access                     = string # Allow | Deny
      protocol                   = string # Tcp | Udp | Icmp | *
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))

  default = {
    "nsg-web" = {
      rules = [
        {
          name                       = "allow-http"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-https"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    }
    "nsg-app" = {
      rules = [
        {
          name                       = "allow-app-port"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "10.0.0.0/8"  # internal traffic only
          destination_address_prefix = "*"
        },
      ]
    }
    "nsg-data" = {
      rules = [
        {
          name                       = "deny-all-inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    }
  }
}

# ── Resources ────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_network_security_group" "this" {
  # Outer loop: one NSG per map entry.
  for_each = var.network_security_groups

  name                = each.key
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Inner loop (dynamic block): one security_rule per rule in the list.
  # content{} has access to each.value.rules[i] via `rule`.
  dynamic "security_rule" {
    for_each = each.value.rules          # list of rule objects
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = { managed_by = "terraform", nsg = each.key }
}

# ── Outputs ───────────────────────────────────────────────────

output "nsg_ids" {
  description = "Map of NSG name → Azure resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}
