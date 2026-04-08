# =============================================================
# EXAMPLE 5 – Dynamic resource creation using for_each + module
# Level: Advanced
# Concept: Calling a child module once per map entry
# =============================================================
#
# PATTERN: Module-per-instance
# ─────────────────────────────
# Instead of replicating resource blocks in the root module,
# you call a *module* with for_each.  The module encapsulates
# the entire "unit" of infrastructure (VNet + NSG + subnets).
#
# Benefit: standardisation and DRY code across many environments.

# ── Variables ────────────────────────────────────────────────

variable "environments" {
  description = "Map of environment name → its network configuration."
  type = map(object({
    location      = string
    address_space = string # a single CIDR, e.g. "10.0.0.0/16"
    subnets = list(object({
      name   = string
      newbits = number # bits to add to the base prefix
      netnum  = number # ordinal number of the subnet
    }))
  }))

  default = {
    "dev" = {
      location      = "East US"
      address_space = "10.10.0.0/16"
      subnets = [
        { name = "web",  newbits = 8, netnum = 1 },
        { name = "app",  newbits = 8, netnum = 2 },
        { name = "data", newbits = 8, netnum = 3 },
      ]
    }
    "prod" = {
      location      = "West Europe"
      address_space = "10.20.0.0/16"
      subnets = [
        { name = "web",  newbits = 8, netnum = 1 },
        { name = "app",  newbits = 8, netnum = 2 },
        { name = "data", newbits = 8, netnum = 3 },
      ]
    }
  }
}

# ── Module Call ───────────────────────────────────────────────
#
# for_each on a module call creates ONE MODULE INSTANCE
# per entry.  Each instance manages its own set of resources
# (resource group, VNet, subnets, NSG).
#
# Terraform state address:
#   module.network["dev"].azurerm_virtual_network.this
#   module.network["prod"].azurerm_virtual_network.this

module "network" {
  source = "./modules/network" # child module defined below

  for_each = var.environments

  # Variables forwarded to the child module.
  env_name      = each.key
  location      = each.value.location
  address_space = each.value.address_space
  subnets       = each.value.subnets
}

# ── Outputs ───────────────────────────────────────────────────

output "vnet_ids_by_env" {
  description = "VNet resource IDs per environment."
  value = {
    for env, mod in module.network :
    env => mod.vnet_id
  }
}

output "subnet_ids_by_env" {
  description = "Subnet IDs per environment."
  value = {
    for env, mod in module.network :
    env => mod.subnet_ids
  }
}
