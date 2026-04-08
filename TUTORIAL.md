# Terraform `for_each` on Azure — Complete Tutorial

> **Level:** Beginner to Advanced | **Provider:** `azurerm ~> 4.0` | **Terraform:** `~> 1.9`

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Beginner Examples](#2-beginner-examples)
3. [Intermediate Examples](#3-intermediate-examples)
4. [Advanced Examples](#4-advanced-examples)
5. [Real-World Use Cases](#5-real-world-use-cases)
6. [Best Practices](#6-best-practices)
7. [for_each vs count](#7-for_each-vs-count)
8. [Exercises](#8-exercises)

---

## 1. Introduction

### What is `for_each`?

`for_each` is a **meta-argument** you attach to a `resource` or `module` block that tells Terraform to create **one instance for every item** in a map or set you supply.

It accepts two collection types:

| Input type | `each.key` | `each.value` |
|---|---|---|
| `set(string)` | the string itself | same as key |
| `map(any)` | the map key | the map value |

State addresses are **named**, not positional:

```
azurerm_resource_group.env["dev"]
azurerm_resource_group.env["prod"]
```

### `for_each` vs `count`

```hcl
variable "envs" {
  description = "List of environments"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

# count — positional indices
resource "azurerm_resource_group" "count_example" {
  count    = length(var.envs)
  name     = "rg-${var.envs[count.index]}"   # rg-dev, rg-staging, rg-prod
  location = "East US"
}

# for_each — named keys
resource "azurerm_resource_group" "foreach_example" {
  for_each = toset(var.envs)
  name     = "rg-${each.key}"                # rg-dev, rg-staging, rg-prod
  location = "East US"
}
```

> **IMPORTANT**
> With `count`, removing "staging" from the list renumbers all subsequent indices and **may destroy-recreate prod**. With `for_each`, removing "staging" only affects `env["staging"]`.

### When to use `for_each`

- Creating multiple similar resources
- Collections where items may be added or removed
- When each item needs different attributes
- When you want to reference instances by name

---

## 2. Beginner Examples

### Example 1 — Multiple Resource Groups (set of strings)

**File:** `01_beginner/example1_resource_groups/main.tf`

```hcl
variable "resource_groups" {
  description = "Set of environment names. One RG per name."
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}

resource "azurerm_resource_group" "env" {
  for_each = var.resource_groups   # each.key == each.value for a set

  name     = "rg-${each.key}"
  location = "East US"
  tags     = { environment = each.key, managed_by = "terraform" }
}

output "resource_group_ids" {
  value = { for env, rg in azurerm_resource_group.env : env => rg.id }
}
```

---

### Example 2 — Multiple Storage Accounts (map of strings)

**File:** `01_beginner/example2_storage_accounts/main.tf`

```hcl
variable "storage_accounts" {
  description = "Map of short name to replication SKU."
  type        = map(string)
  default = {
    logs        = "Standard_LRS"
    backups     = "Standard_GRS"
    application = "Standard_ZRS"
  }
}

resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                     = "st${each.key}tutorial001"  
  resource_group_name      = "rg-storage-tutorial"
  location                 = "West Europe"
  account_tier             = "Standard"
  account_replication_type = each.value  # LRS / GRS / ZRS from map value
}
```

---

## 3. Intermediate Examples

### Example 3 — VNets with Subnets (nested map + flattening)

**File:** `02_intermediate/example3_vnets_subnets/main.tf`

**The challenge:** Subnets live *inside* VNets in the variable, but a Terraform resource block cannot be nested inside another resource block.

```hcl
variable "virtual_networks" {
  type = map(object({
    location      = string
    address_space = list(string)
    subnets = map(object({
      address_prefix = string
    }))
  }))
  default = {
    "vnet-frontend" = {
      location      = "East US"
      address_space = ["10.10.0.0/16"]
      subnets = {
        "snet-web" = { address_prefix = "10.10.1.0/24" }
        "snet-app" = { address_prefix = "10.10.2.0/24" }
      }
    }
  }
}

# VNets: one per map entry
resource "azurerm_virtual_network" "this" {
  for_each            = var.virtual_networks
  name                = each.key
  location            = each.value.location
  resource_group_name = "rg-network"
  address_space       = each.value.address_space
}

# Flatten: "vnet-name/subnet-name" => { config }
locals {
  subnets_flat = {
    for vnet_key, vnet_val in var.virtual_networks :
    "${vnet_key}/${subnet_key}" => {
      vnet_key   = vnet_key
      subnet_key = subnet_key
      subnet_val = subnet_val
    }
    if true
    for subnet_key, subnet_val in vnet_val.subnets
  }
}

# Subnets: one per flattened entry
resource "azurerm_subnet" "this" {
  for_each             = local.subnets_flat
  name                 = each.value.subnet_key
  resource_group_name  = "rg-network"
  virtual_network_name = each.value.vnet_key
  address_prefixes     = [each.value.subnet_val.address_prefix]
  depends_on           = [azurerm_virtual_network.this]
}
```

**Step-by-step logic for `locals` and `for` loop:**
1. **Why `locals`?** Terraform's `for_each` can only accept flat maps or sets. We use `locals` to compute a new data structure in memory to reshape our nested variable into a single flat map.
2. **Why the `for` loop?** The `for` expression runs a double loop here. It iterates over every VNet (`vnet_val`), and then iterates over every subnet inside it (`subnet_val`). 
3. **The specific output:** By combining strings like `"${vnet_key}/${subnet_key}"`, we guarantee unique primary keys in the new map dictating the creation of each subnet resource later (`for_each = local.subnets_flat`).

---

### Example 4 — Linux Virtual Machines (complex objects + optional())

**File:** `02_intermediate/example4_complex_maps/main.tf`

This example uses Azure Linux VMs to show how `optional(type, default)` works in Terraform 1.3+.

```hcl
variable "virtual_machines" {
  description = "Map of VM name to detailed schema configuration."
  type = map(object({
    size           = string
    admin_username = string
    
    # optional() allows callers to omit 'os_disk', substituting the defaults automatically.
    os_disk = optional(object({
      caching              = string
      storage_account_type = string
    }), {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    })
    
    tags = optional(map(string), {})
  }))
  
  default = {
    "vm-frontend" = {
      size           = "Standard_B2s"
      admin_username = "azureuser"
      # Notice we omitted os_disk - defaults applied automatically!
    }
    "vm-backend" = {
      size           = "Standard_D2s_v3"
      admin_username = "adminuser"
      os_disk = {
        caching              = "ReadOnly"
        storage_account_type = "Premium_LRS"
      }
      tags = { critical = "true" }
    }
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each            = var.virtual_machines
  name                = each.key
  resource_group_name = "rg-vms"
  location            = "East US"
  size                = each.value.size
  admin_username      = each.value.admin_username
  disable_password_authentication = true
  
  admin_ssh_key {
    username   = each.value.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  
  network_interface_ids = [ azurerm_network_interface.this[each.key].id ]

  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = merge({ managed_by = "terraform" }, each.value.tags)
}
```

---

## 4. Advanced Examples

### Example 5 — `for_each` on a Module Call

**Files:** `03_advanced/example5_module_foreach/`

```hcl
variable "environments" {
  type = map(object({
    location      = string
    address_space = string
    subnets       = list(object({ name = string, newbits = number, netnum = number }))
  }))
  default = {
    "dev" = {
      location      = "East US"
      address_space = "10.10.0.0/16"
      subnets       = [{ name = "web", newbits = 8, netnum = 1 }]
    }
  }
}

# Root module — one network stack per environment
module "network" {
  source   = "./modules/network"
  for_each = var.environments   # loops over every dev/staging/prod object map

  env_name      = each.key
  location      = each.value.location
  address_space = each.value.address_space
  subnets       = each.value.subnets
}
```

Inside the child module (`modules/network/main.tf`), `for`-loops process the custom CIDRs calculation locally:

```hcl
locals {
  subnet_map = {
    for s in var.subnets :
    s.name => { address_prefix = cidrsubnet(var.address_space, s.newbits, s.netnum) }
  }
}
resource "azurerm_subnet" "this" {
  for_each         = local.subnet_map
  name             = "snet-${each.key}"
  address_prefixes = [each.value.address_prefix]
}
```

**Step-by-step logic for `locals` and `for` mapping block in child module:**
1. **Why `locals`?** Once we receive an array list variable (`var.subnets`), we can't reliably loop through items in `for_each` without converting it to a `map`.
2. **Why the `for` loop?** The expression loops over the array `var.subnets`, reading each object, and computes physical subnet IPs via Terraform's `cidrsubnet` function dynamically. It outputs an easily digestible schema mapping name identifiers to their parsed CIDR values!

---

### Example 6 — Conditional Creation with Filtered Maps

**File:** `03_advanced/example6_conditional_filtered/main.tf`

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

variable "all_storage_accounts" {
  type = map(object({ environment = string, sku = string }))
  default = {
    "salogsdev001"   = { environment = "dev",  sku = "Standard_LRS" }
    "salogsstagin001"= { environment = "staging", sku = "Standard_GRS" }
    "salogsprod001"  = { environment = "prod", sku = "Standard_GRS" }
  }
}

locals {
  # Filter: only keep entries matching the active workspace
  filtered_storage = {
    for name, cfg in var.all_storage_accounts :
    name => cfg
    if cfg.environment == var.environment
  }
}

resource "azurerm_storage_account" "this" {
  for_each                 = local.filtered_storage
  name                     = each.key
  account_replication_type = each.value.sku
  # ...
}
```

**Step-by-step logic for `locals` filter loop:**
1. **Why `locals`?** We aim to separate business logic (evaluating what accounts to skip safely or deploy conditionally) from declarative block deployment attributes (`resource "xyz"`).
2. **Why the `for` along with `if` check?** This reads every object in `all_storage_accounts`. It employs a conditional statement (`if cfg.environment == var.environment`). If false, the item is entirely discarded from evaluating into `filtered_storage`. 

---

### Example 7 — `for_each` + `dynamic` Blocks

**File:** `03_advanced/example7_dynamic_blocks/main.tf`

```hcl
variable "network_security_groups" {
  type = map(object({
    rules = list(object({
      name                   = string
      priority               = number
      destination_port_range = string
    }))
  }))
  default = {
    "nsg-web" = {
      rules = [
        { name = "http",  priority = 100, destination_port_range = "80" },
        { name = "https", priority = 110, destination_port_range = "443" }
      ]
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each            = var.network_security_groups  # outer: one NSG
  name                = each.key
  location            = "East US"
  resource_group_name = "rg-network"

  dynamic "security_rule" {             # inner: one rule per list item
    for_each = each.value.rules
    content {
      name                   = security_rule.value.name
      priority               = security_rule.value.priority
      destination_port_range = security_rule.value.destination_port_range
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      # ... required networking fields here
    }
  }
}
```

---

## 5. Real-World Use Cases

### UC-1: Multi-Environment Deployments

**Problem:** Managing dev, staging, and prod config manually causes deployment drift.

```hcl
variable "environments" {
  type = map(object({ location = string, plan_sku = string, worker_count = number }))
  default = {
    dev     = { location = "East US",     plan_sku = "B1",   worker_count = 1 }
    staging = { location = "East US",     plan_sku = "P1v3", worker_count = 2 }
    prod    = { location = "West Europe", plan_sku = "P3v3", worker_count = 5 }
  }
}
resource "azurerm_service_plan" "env" {
  for_each     = var.environments
  name         = "asp-myapp-${each.key}"
  sku_name     = each.value.plan_sku
  worker_count = each.value.worker_count
  os_type      = "Linux"
}
```

---

### UC-2: Multi-Region Rollout

**Problem:** Deploying identical infra to 3+ regions manually is tedious.

```hcl
variable "regions" {
  type = map(object({ cidr_offset = number }))
  default = {
    eastus = { cidr_offset = 0 }
    westeurope = { cidr_offset = 1 }
    southeastasia = { cidr_offset = 2 }
  }
}

locals {
  region_cidrs = {
    for region, cfg in var.regions :
    region => cidrsubnet("10.0.0.0/8", 8, cfg.cidr_offset)
  }
}
# eastus -> 10.0.0.0/16 | westeurope -> 10.1.0.0/16 | southeastasia -> 10.2.0.0/16

resource "azurerm_virtual_network" "region" {
  for_each      = var.regions
  name          = "vnet-platform-${each.key}"
  location      = each.key
  address_space = [local.region_cidrs[each.key]]
}
```

**Step-by-step logic:**
1. **Why `locals`?** Reusing static IP logic directly in resource properties invites error duplication.
2. **Why `for`?** By looping over `var.regions`, we use Terraform's internal math utility module `cidrsubnet()` returning specific non-overlapping `/16` addresses mapped exactly to each region.

---

### UC-3: RBAC Assignments at Scale

**Problem:** Handling repetitive Access-Control lists limits maintainability across many environments.

```hcl
variable "role_assignments" {
  type = map(object({
    scope                = string
    role_definition_name = string
    principal_id         = string
  }))
  default = {
    "data-team-rg-reader" = {
      scope                = "/subscriptions/0000-0000/resourceGroups/rg-data"
      role_definition_name = "Reader"
      principal_id         = "11111111-1111-1111-1111-111111111111"
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
```

---

### UC-4: Tag Standardisation

**Problem:** Inconsistent tags on infrastructure.

```hcl
variable "workloads" {
  type = map(object({
    cost_center = string
    owner       = string
    environment = string
  }))
  default = {
    "payments-api" = { cost_center = "CC-123", owner = "platform", environment = "prod" }
  }
}

locals {
  mandatory_tags = { managed_by = "terraform", last_modified = "2025-01-01" }
  workload_tags = {
    for name, cfg in var.workloads :
    name => merge(local.mandatory_tags, {
      workload    = name
      cost_center = cfg.cost_center
      owner       = cfg.owner
      environment = cfg.environment
    })
  }
}
resource "azurerm_resource_group" "workload" {
  for_each = var.workloads
  name     = "rg-${each.key}"
  location = "East US"
  tags     = local.workload_tags[each.key]  # full merged tag set enforcement
}
```

**Step-by-step logic:**
1. **Why `locals`?** Constant baseline tags (`mandatory_tags`) apply company-wide standard defaults avoiding human error replication.
2. **Why `for`?** By iterating all declared workloads sequentially via user logic, we construct a new dataset mapping merging (`merge()`) both baseline requirements alongside user inputs guaranteeing every deployed RG will be 100% compliant!

---

## 6. Best Practices

### DO

| Practice | Reason |
|---|---|
| Use **descriptive, stable keys** | Keys are state addresses; changing them forces destroy+create. |
| Use `map(object(...))` not `map(any)` | Prevents unexpected type coercion logic errors when testing. |
| Use `optional(type, default)` | Excellent backwards compatibility behavior in newer schemas. |
| **Flatten structures in `locals`** | Allows your resource definition to read elegantly cleanly. |

### DON'T

| Anti-pattern | Problem |
|---|---|
| Integer string keys | Overrides the main benefit of keys, falling apart if indices drop. |
| Computed/unknown collections | Terraform requires the full collection evaluated prior to API Planning. |
| Missing `moved` mapping | Terraform assumes deletions rather than safe, logical renames. |

## 7. `for_each` vs `count`

| Scenario | Use |
|---|---|
| Binary Boolean Toggle logic | `count = condition ? 1 : 0` |
| Multiple indistinguishable clones | `count = N` |
| Readily Named collection maps | `for_each = map` |
| Items needing future list deletion  | `for_each = set/map` |
| Different attributes mapped | `for_each = map(object)` |

## 8. Exercises

See `05_exercises/exercises.tf` mapped correctly in the file base directory path to run 5 hands-on evaluations spanning Beginner and Advanced syntax implementations!
