# =============================================================
# REAL-WORLD USE CASE 3 – RBAC at scale
# =============================================================
# Problem: Assigning Azure roles to service principals /
# managed identities across multiple scopes by hand is slow
# and error-prone.
#
# Solution: Define assignments as a map and for_each handles
# the creation.  Adding / removing an assignment is a one-line
# variable change.

variable "role_assignments" {
  description = <<-DESC
    Map of unique logical key → RBAC assignment spec.
    Use descriptive keys – they become the Terraform resource
    address and appear in plan output.
  DESC

  type = map(object({
    scope                = string # Azure resource ID or subscription
    role_definition_name = string # Built-in role name
    principal_id         = string # Object ID of identity
  }))

  # Example: granting the data team read-only access to two
  # storage accounts.
  default = {
    "data-team-sa-logs-reader" = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/salogsdata"
      role_definition_name = "Storage Blob Data Reader"
      principal_id         = "11111111-1111-1111-1111-111111111111"
    }
    "data-team-sa-raw-reader" = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/sarawdata"
      role_definition_name = "Storage Blob Data Reader"
      principal_id         = "11111111-1111-1111-1111-111111111111"
    }
    "devops-rg-contributor" = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-deploy"
      role_definition_name = "Contributor"
      principal_id         = "22222222-2222-2222-2222-222222222222"
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id

  # Descriptive key feeds into the stable Terraform address:
  # azurerm_role_assignment.this["data-team-sa-logs-reader"]
}

output "role_assignment_ids" {
  description = "Map of logical key → role assignment ID."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}
