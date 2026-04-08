# =============================================================
# EXERCISES – Hands-on practice
# =============================================================
# These files contain STARTER CODE (variables + resource stubs).
# Each exercise has a TODO comment telling you what to build.
# Solutions are in ./solutions/

# ─────────────────────────────────────────────────────────────
# Exercise 1 (Beginner) – Deploy Resource Groups
# Difficulty: ⭐
# ─────────────────────────────────────────────────────────────
# TASK: Fill in the for_each resource block so Terraform
# creates one resource group per entry in `exercise_rgs`.

variable "exercise_rgs" {
  description = "Resource group names to create."
  type        = set(string)
  default     = ["rg-exercise-alpha", "rg-exercise-beta", "rg-exercise-gamma"]
}

variable "exercise_location" {
  description = "Default location for exercises."
  type        = string
  default     = "East US"
}

# TODO: uncomment and complete this resource block.
#
# resource "azurerm_resource_group" "exercise1" {
#   for_each = ???
#   name     = ???
#   location = ???
# }

# ─────────────────────────────────────────────────────────────
# Exercise 2 (Beginner) – Storage accounts from a map
# Difficulty: ⭐⭐
# ─────────────────────────────────────────────────────────────
# TASK: Create storage accounts using SAName → Replication SKU

variable "exercise_storage_map" {
  type = map(string)
  default = {
    "saexerciseprimary001" = "Standard_LRS"
    "saexercisebkp001"    = "Standard_GRS"
  }
}

# TODO: Create azurerm_resource_group   "exercise2"
#       Create azurerm_storage_account  "exercise2"
#       Use for_each = var.exercise_storage_map
#       account_replication_type = each.value

# ─────────────────────────────────────────────────────────────
# Exercise 3 (Intermediate) – VNets + Subnets from a map of objects
# Difficulty: ⭐⭐⭐
# ─────────────────────────────────────────────────────────────
# TASK:
#   1. Create one VNet per entry using for_each
#   2. Flatten subnets into a local map (use the pattern from Example 3)
#   3. Create subnets using the flattened map

variable "exercise_vnets" {
  type = map(object({
    location      = string
    address_space = string
    subnets       = map(string) # subnet_name → CIDR
  }))
  default = {
    "vnet-exercise-a" = {
      location      = "East US"
      address_space = "192.168.0.0/16"
      subnets = {
        "web"  = "192.168.1.0/24"
        "data" = "192.168.2.0/24"
      }
    }
    "vnet-exercise-b" = {
      location      = "West Europe"
      address_space = "172.16.0.0/16"
      subnets = {
        "api" = "172.16.1.0/24"
      }
    }
  }
}

# TODO: implement resources here.

# ─────────────────────────────────────────────────────────────
# Exercise 4 (Advanced) – Conditional creation with filtered map
# Difficulty: ⭐⭐⭐⭐
# ─────────────────────────────────────────────────────────────
# TASK: Given the `exercise_all_rgs` catalogue below,
#   1. Create a local that filters to active = true entries ONLY
#   2. Create resource groups for the filtered set
#   3. Add an output showing how many were deployed

variable "exercise_all_rgs" {
  type = map(object({
    location = string
    active   = bool
  }))
  default = {
    "rg-active-1" = { location = "East US",    active = true  }
    "rg-active-2" = { location = "West Europe", active = true  }
    "rg-disabled" = { location = "East US",    active = false }
  }
}

# TODO: locals { active_rgs = { for ... : ... => ... if ... } }
# TODO: resource "azurerm_resource_group" "exercise4" { ... }
# TODO: output "active_count" { ... }

# ─────────────────────────────────────────────────────────────
# Exercise 5 (Advanced) – Dynamic blocks inside for_each
# Difficulty: ⭐⭐⭐⭐⭐
# ─────────────────────────────────────────────────────────────
# TASK: Deploy one NSG per application tier.  Each tier has a
# different list of allowed ports.
# Use for_each + dynamic "security_rule" to accomplish this.

variable "exercise_tiers" {
  type = map(object({
    allowed_ports = list(number)
  }))
  default = {
    "web"  = { allowed_ports = [80, 443] }
    "api"  = { allowed_ports = [8080, 8443] }
    "data" = { allowed_ports = [5432] }
  }
}

# HINT: dynamic "security_rule" iterates each.value.allowed_ports
# Use priority = 100 + index(each.value.allowed_ports, security_rule.value)

# TODO: resource "azurerm_resource_group" "exercise5" { ... }
# TODO: resource "azurerm_network_security_group" "exercise5" {
#         for_each = var.exercise_tiers
#         dynamic "security_rule" {
#           for_each = each.value.allowed_ports
#           content { ... }
#         }
#       }
