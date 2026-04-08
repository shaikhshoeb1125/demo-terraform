# =============================================================
# EXAMPLE 1 – Creating multiple Resource Groups using for_each
# Level: Beginner
# Concept: for_each on a simple set of strings
# =============================================================
#
# WHAT IS for_each?
# ─────────────────
# for_each is a Terraform meta-argument that tells a resource
# block to create *one instance* for every item in a map or
# set you supply.
#
# WHY NOT count?
# ──────────────
# count uses positional integers.  If you remove "dev" from
# the middle of a list, Terraform renumbers every index after
# it and may destroy/re-create resources you wanted to keep.
# for_each uses *named keys*, so removing one item only
# affects that one resource.

# ── Input Variables ──────────────────────────────────────────

variable "resource_groups" {
  description = "Set of environment names – one resource group is created per name."
  type        = list(any)
  default     = ["dev", "staging", "prod"]
}

variable "location" {
  description = "Azure region for all resource groups."
  type        = string
  default     = "Central India"
}

variable "tags" {
  description = "Tags applied to every resource group."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "for-each-practise"
  }
}

# ── Resources ────────────────────────────────────────────────

resource "azurerm_resource_group" "env" {
  # for_each iterates over the set defined above.
  # each.key  → the string from the set (e.g. "dev", "staging", "prod")
  # each.value → same as each.key when iterating over a set
  for_each = toset(var.resource_groups)

  name     = "rg-${each.key}" # e.g. rg-dev, rg-staging, rg-prod
  location = var.location
  tags     = merge(var.tags, { environment = each.key })
}

resource "azurerm_resource_group" "rg-dev" {
  name     = "rg-dev"
  location = "East US"
}

# ── Outputs ───────────────────────────────────────────────────

output "resource_group_ids" {
  description = "Map of environment → resource group ID."
  value       = { for k, v in azurerm_resource_group.env : k => v.id }
}

output "rg-dev-id" {
  value = azurerm_resource_group.rg-dev.id
}

output "resource_group_names" {
  description = "List of all created resource group names."
  value       = [for rg in azurerm_resource_group.env : rg.name]
}

# ── Explanation of output block ───────────────────────────────────────────────────

# [for rg in azurerm_resource_group.env : rg.name]
# "It simply means look at every resource group we just created, grab its name, and put all those names into a neat list."

# ### Detailed break-down
# 1. `azurerm_resource_group.env` → This is just the pile of all resource groups** your code created (`dev`, `staging`, `prod`, etc.).
# 2. `for rg in ...` → Terraform picks them up one by one. `rg` is just a temporary nickname meaning "the current resource group I'm holding".
# 3. `rg.name` → For that one resource group, add its name (like `"rg-dev"`).
# 4. `[ ... ]` → The square brackets mean: "Collect all those names into a list."

# Result:
# ["rg-dev", "rg-staging", "rg-prod"]


