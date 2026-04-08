# =============================================================
# REAL-WORLD USE CASE 4 – Tag standardisation across resources
# =============================================================
# Problem: Resources lack consistent tagging, making cost
# allocation and compliance reporting unreliable.
#
# Solution: Define a mandatory tag schema in a variable and
# apply it uniformly via locals + for_each.

variable "workloads" {
  description = "Workloads to deploy.  Each gets a resource group with enforced tags."
  type = map(object({
    location    = string
    owner       = string
    cost_center = string
    environment = string
  }))

  default = {
    "payments-api" = {
      location    = "East US"
      owner       = "platform-team@example.com"
      cost_center = "CC-1234"
      environment = "prod"
    }
    "analytics-pipeline" = {
      location    = "West Europe"
      owner       = "data-team@example.com"
      cost_center = "CC-5678"
      environment = "prod"
    }
    "sandbox" = {
      location    = "East US"
      owner       = "developers@example.com"
      cost_center = "CC-0000"
      environment = "dev"
    }
  }
}

# A local builds the **mandatory** base tags; callers cannot omit them.
locals {
  mandatory_tags = { managed_by = "terraform", last_modified = "2025-01-01" }

  # Merge mandatory tags with per-workload tags.
  workload_tags = {
    for name, cfg in var.workloads :
    name => merge(local.mandatory_tags, {
      workload    = name
      owner       = cfg.owner
      cost_center = cfg.cost_center
      environment = cfg.environment
    })
  }
}

resource "azurerm_resource_group" "workload" {
  for_each = var.workloads

  name     = "rg-${each.key}"
  location = each.value.location

  # every RG gets the full, merged tag set
  tags = local.workload_tags[each.key]
}

output "workload_tags_preview" {
  description = "Full tag set that will be applied to each workload RG."
  value       = local.workload_tags
}

# =============================================================
# REAL-WORLD USE CASE 5 – Multi-tenant / Multi-client isolation
# =============================================================
# Problem: A SaaS product must onboard new customers quickly
# while keeping resources fully isolated.
#
# Solution: Each tenant key in a variable triggers creation of
# an isolated resource group, storage account, and key vault.

variable "tenants" {
  description = "SaaS tenants.  One isolated stack is created per entry."
  type = map(object({
    location = string
    tier     = string # "starter" | "pro" | "enterprise"
  }))

  default = {
    "contoso"  = { location = "East US",   tier = "pro" }
    "fabrikam" = { location = "West Europe", tier = "enterprise" }
    "northwind" = { location = "East US",  tier = "starter" }
  }
}

locals {
  # Map tier → storage SKU for cost differentiation.
  tier_to_sku = {
    starter    = "Standard_LRS"
    pro        = "Standard_GRS"
    enterprise = "Standard_ZRS"
  }
}

resource "azurerm_resource_group" "tenant" {
  for_each = var.tenants

  name     = "rg-tenant-${each.key}"
  location = each.value.location
  tags     = { tenant = each.key, tier = each.value.tier, managed_by = "terraform" }
}

resource "azurerm_storage_account" "tenant" {
  for_each = var.tenants

  # Storage names must be globally unique and ≤24 chars.
  name                     = "st${substr(each.key, 0, 14)}001"
  resource_group_name      = azurerm_resource_group.tenant[each.key].name
  location                 = azurerm_resource_group.tenant[each.key].location
  account_tier             = "Standard"
  account_replication_type = local.tier_to_sku[each.value.tier]

  tags = { tenant = each.key }
}

resource "azurerm_key_vault" "tenant" {
  for_each = var.tenants

  name                = "kv-${substr(each.key, 0, 10)}-001"
  resource_group_name = azurerm_resource_group.tenant[each.key].name
  location            = azurerm_resource_group.tenant[each.key].location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = each.value.tier == "enterprise" ? "premium" : "standard"

  tags = { tenant = each.key, tier = each.value.tier }
}

data "azurerm_client_config" "current" {}

output "tenant_storage_endpoints" {
  value = { for k, v in azurerm_storage_account.tenant : k => v.primary_blob_endpoint }
}
