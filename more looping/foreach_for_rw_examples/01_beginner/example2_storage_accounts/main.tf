# =============================================================
# EXAMPLE 2 – Creating multiple Storage Accounts from a map
# Concept: for_each over a map(string)
# =============================================================
#
# HOW IS A MAP DIFFERENT FROM A SET?
# ───────────────────────────────────
# A set only gives you the item itself.
# A map gives you key → value pairs, so you can attach extra
# configuration to each key.
#
# In a map, for_each exposes:
#   each.key   → the map key   (e.g. "logs")
#   each.value → the map value (e.g. "Standard_LRS")

# ── Input Variables ──────────────────────────────────────────

variable "resource_group_name" {
  description = "Resource group that will hold the storage accounts."
  type        = string
  default     = "rg-storage-practise"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "West India"
}

# Map: name → SKU (account tier)
variable "storage_accounts" {
  description = "Map of short name → SKU for each storage account."
  type        = map(string)
  default = {
    logs        = "LRS" # cheaper, local redundancy
    backups     = "LRS" # zone-redundant
    application = "GRS" # geo-redundant
  }
}

# ── Resources ────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "this" {
  # Iterate over each entry in the map.
  # each.key   = short name  (logs / backups / application)
  # each.value = SKU string  (Standard_LRS / Standard_GRS / …)
  for_each = var.storage_accounts

  # Storage account names must be globally unique, 3-24 lower-case
  # alphanumeric chars.  We add a fixed suffix to avoid collisions.
  name                     = "st${each.key}practise001"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = each.value # ← LRS / GRS / ZRS

  tags = {
    managed_by = "terraform"
    purpose    = each.key
    sku        = each.value
  }
}

# ── Outputs ───────────────────────────────────────────────────

output "storage_account_primary_endpoints" {
  description = "Map of short name → primary blob endpoint."
  value = {
    for name, sa in azurerm_storage_account.this :
    name => sa.primary_blob_endpoint
  }
}

output "sa-endpoints" {
  value = { for k, v in azurerm_storage_account.this : k => v.primary_blob_endpoint }
}

output "logs-sa-endpoint" {
  value = azurerm_storage_account.this["logs"].primary_blob_endpoint
}
