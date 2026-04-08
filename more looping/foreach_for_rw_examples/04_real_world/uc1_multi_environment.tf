# =============================================================
# REAL-WORLD USE CASE 1 – Multi-environment deployments
# =============================================================
# Problem: Each environment (dev / staging / prod) needs its
# own set of resources, with different SKUs and sizes.
#
# Solution: A single variable describes ALL environments.
# for_each stamps out one resource group + app service plan
# per entry.  Environment-specific sizing is in the variable.

variable "environments" {
  description = "All environments and their app service plan settings."
  type = map(object({
    location     = string
    plan_sku     = string # e.g. "B1", "P2v3"
    worker_count = number
  }))

  default = {
    dev = {
      location     = "East US"
      plan_sku     = "B1"
      worker_count = 1
    }
    staging = {
      location     = "East US"
      plan_sku     = "P1v3"
      worker_count = 2
    }
    prod = {
      location     = "West Europe"
      plan_sku     = "P3v3"
      worker_count = 5
    }
  }
}

resource "azurerm_resource_group" "env" {
  for_each = var.environments

  name     = "rg-myapp-${each.key}"
  location = each.value.location
  tags     = { environment = each.key, managed_by = "terraform" }
}

resource "azurerm_service_plan" "env" {
  for_each = var.environments

  name                = "asp-myapp-${each.key}"
  resource_group_name = azurerm_resource_group.env[each.key].name
  location            = azurerm_resource_group.env[each.key].location
  os_type             = "Linux"
  sku_name            = each.value.plan_sku
  worker_count        = each.value.worker_count
}

output "service_plan_ids" {
  value = { for k, v in azurerm_service_plan.env : k => v.id }
}
