# =============================================================
# EXAMPLE 6 – Conditional resource creation: filtered maps
# Level: Advanced
# Concept: for expressions to filter a map before passing to
#          for_each, so only matching resources are created.
# =============================================================
#
# REAL-WORLD PROBLEM:
# You have a single variable describing ALL storage accounts
# across environments.  In the "dev" workspace you only want
# "dev" accounts; in "prod" only "prod" accounts.
#
# SOLUTION: Filter the map with a for expression.

# ── Input Variables ──────────────────────────────────────────

variable "environment" {
  description = "Active environment.  Only resources for this env are created."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "East US"
}

# Master catalogue – every storage account across all environments.
variable "all_storage_accounts" {
  description = <<-DESC
    Master catalogue indexed by unique name.
    The 'environment' attribute controls which workspace the SA is deployed to.
  DESC

  type = map(object({
    environment  = string       # dev | staging | prod
    sku          = string
    enable_https = optional(bool, true)
  }))

  default = {
    "salogsdev001"     = { environment = "dev",     sku = "Standard_LRS" }
    "sabkpdev001"      = { environment = "dev",     sku = "Standard_LRS" }
    "salogsstagin001"  = { environment = "staging",  sku = "Standard_GRS" }
    "salogsprod001"    = { environment = "prod",     sku = "Standard_GRS" }
    "sadataprod001"    = { environment = "prod",     sku = "Standard_ZRS" }
  }
}

# ── Locals: filter the catalogue ──────────────────────────────

locals {
  # Keep only the entries whose 'environment' field matches the active env.
  # This filtered map is then fed to for_each.
  filtered_storage = {
    for name, cfg in var.all_storage_accounts :
    name => cfg
    if cfg.environment == var.environment
  }
}

# ── Resources ────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = "rg-storage-${var.environment}"
  location = var.location
}

resource "azurerm_storage_account" "this" {
  for_each = local.filtered_storage  # ← only env-matching entries

  name                     = each.key
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = each.value.sku

  # Optional with default — safe even when the caller omits the field.
  https_traffic_only_enabled = each.value.enable_https

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── Outputs ───────────────────────────────────────────────────

output "deployed_storage_accounts" {
  description = "Storage accounts deployed in the active environment."
  value       = { for k, v in azurerm_storage_account.this : k => v.primary_blob_endpoint }
}

output "filtered_count" {
  description = "Number of storage accounts in this environment."
  value       = length(local.filtered_storage)
}
