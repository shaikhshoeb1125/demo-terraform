# Azure Hub-and-Spoke Network Architecture

This Terraform configuration deploys a secure, production-ready hub-and-spoke network architecture in Azure with **environment-based spokes** (dev, uat, prod), following the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/pillars) pillars.

## Architecture Overview

This implementation creates a centralized hub VNet with shared security services (Azure Firewall, Azure Bastion) and **three spoke VNets for different environments** (dev, uat, prod). Each spoke contains **three subnets** for a three-tier application architecture (web, app, db).

### Key Components

**Hub VNet** (10.0.0.0/16):
- Azure Firewall for centralized traffic inspection and filtering
- Azure Bastion for secure VM access (no public IPs on VMs)
- Gateway Subnet for VPN/ExpressRoute connectivity (optional)
- Management Subnet for administrative resources

**Spoke VNets** (Environment-Based):
- **Dev Spoke** (10.1.0.0/16):
  - Web Subnet (10.1.1.0/24) - Frontend tier
  - App Subnet (10.1.2.0/24) - Application tier
  - DB Subnet (10.1.3.0/24) - Database tier

- **UAT Spoke** (10.2.0.0/16):
  - Web Subnet (10.2.1.0/24) - Frontend tier
  - App Subnet (10.2.2.0/24) - Application tier
  - DB Subnet (10.2.3.0/24) - Database tier

- **Prod Spoke** (10.3.0.0/16):
  - Web Subnet (10.3.1.0/24) - Frontend tier
  - App Subnet (10.3.2.0/24) - Application tier
  - DB Subnet (10.3.3.0/24) - Database tier

**Security Features**:
- Network Security Groups (NSGs) on all subnets with least-privilege rules
- User Defined Routes (UDRs) forcing all spoke traffic through Azure Firewall
- No public IPs on workload VMs
- Secure access via Azure Bastion only
- Azure Firewall Policy with network and application rules
- Environment-based isolation with dedicated resource groups and VNets

**High Availability**:
- Zone-redundant deployment across availability zones
- Multi-zone VMs for resilience
- Redundant connectivity via VNet peering

## Azure Well-Architected Framework Alignment

| Pillar | Implementation |
|--------|---------------|
| **Reliability** | Multi-zone deployment, redundant connectivity, health monitoring |
| **Security** | Defense-in-depth with Firewall, NSGs, Bastion, no public IPs, managed identities, environment isolation |
| **Cost Optimization** | Right-sized VM SKUs per environment (B-series for dev, D/E-series for uat/prod), efficient routing, consolidated security services |
| **Operational Excellence** | Consistent tagging, modular design, IaC with Terraform, environment-based organization |
| **Performance Efficiency** | Optimized network paths, VNet peering for low latency |

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.3
- Azure CLI (optional, for authentication)
- SSH key pair for VM authentication

## Deployment Instructions

### 1. Clone or Initialize

```bash
# Initialize Terraform
terraform init
```

### 2. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

**Required variables to configure:**
- `admin_ssh_public_key`: Your SSH public key for VM access

Generate SSH key if needed:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
cat ~/.ssh/id_rsa.pub  # Copy this value to terraform.tfvars
```

**Optional variables to customize:**
- `prefix`: Resource naming prefix (default: "azhs")
- `location`: Azure region (default: "eastus")
- `environments`: List of environments to deploy (default: ["dev", "uat", "prod"])
- `spoke_vnet_address_spaces`: Network address spaces per environment
- `vm_sizes`: VM SKUs per environment and tier
- `deploy_vms`: Whether to deploy example VMs (default: true)
- `deploy_gateway_subnet`: Whether to deploy Gateway Subnet (default: true)
- `tags`: Additional tags for resource organization

### 3. Review the Plan

```bash
terraform plan
```

Review the resources that will be created (~100+ resources with 3 environments).

### 4. Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes approximately 20-30 minutes.

### 5. Access VMs

After deployment, use Azure Bastion to access VMs:

1. Navigate to Azure Portal
2. Go to the VM you want to access
3. Click **Connect** > **Bastion**
4. Enter username from `admin_username` variable
5. Select **SSH Private Key** and provide your private key

## Architecture Diagram

```
                     ┌─────────────────────────────────┐
                     │        Hub VNet (10.0.0.0/16)   │
                     │                                 │
                     │  ┌─────────────┐  ┌──────────┐ │
                     │  │   Azure     │  │  Azure   │ │
                     │  │  Firewall   │  │  Bastion │ │
                     │  └─────────────┘  └──────────┘ │
                     │  ┌─────────────┐                │
                     │  │   Gateway   │                │
                     │  │   Subnet    │                │
                     │  └─────────────┘                │
                     └────────┬────────────────────────┘
                              │ VNet Peering
          ┌───────────────────┼───────────────────┐
          │                   │                   │
┌─────────▼─────────┐  ┌──────▼──────────┐  ┌────▼────────────┐
│  Dev Spoke        │  │  UAT Spoke      │  │  Prod Spoke     │
│  (10.1.0.0/16)    │  │  (10.2.0.0/16)  │  │  (10.3.0.0/16)  │
│                   │  │                 │  │                 │
│  ┌─────────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │ Web Subnet  │  │  │  │    Web    │  │  │  │    Web    │  │
│  │ 10.1.1.0/24 │  │  │  │10.2.1.0/24│  │  │  │10.3.1.0/24│  │
│  │  (Web VM)   │  │  │  │ (Web VM)  │  │  │  │ (Web VM)  │  │
│  └─────────────┘  │  │  └───────────┘  │  │  └───────────┘  │
│  ┌─────────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │ App Subnet  │  │  │  │    App    │  │  │  │    App    │  │
│  │ 10.1.2.0/24 │  │  │  │10.2.2.0/24│  │  │  │10.3.2.0/24│  │
│  │  (App VM)   │  │  │  │ (App VM)  │  │  │  │ (App VM)  │  │
│  └─────────────┘  │  │  └───────────┘  │  │  └───────────┘  │
│  ┌─────────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │ DB Subnet   │  │  │  │    DB     │  │  │  │    DB     │  │
│  │ 10.1.3.0/24 │  │  │  │10.2.3.0/24│  │  │  │10.3.3.0/24│  │
│  │  (DB VM)    │  │  │  │ (DB VM)   │  │  │  │ (DB VM)   │  │
│  └─────────────┘  │  │  └───────────┘  │  │  └───────────┘  │
│                   │  │                 │  │                 │
│  NSG + UDR on     │  │  NSG + UDR on  │  │  NSG + UDR on   │
│  each subnet      │  │  each subnet   │  │  each subnet    │
└───────────────────┘  └─────────────────┘  └─────────────────┘
```

## Network Traffic Flow

1. **Internet to Web Tier**:
   - Traffic flows through Azure Firewall public IP
   - Firewall applies application rules
   - Routes to appropriate environment's Web VM

2. **Web to App Tier** (within environment):
   - Traffic from Web VM routes to Azure Firewall (via UDR)
   - Firewall inspects and allows (network rules)
   - Routes to App VM in same environment

3. **App to DB Tier** (within environment):
   - Traffic from App VM routes to Azure Firewall (via UDR)
   - Firewall inspects and allows database ports
   - Routes to DB VM in same environment

4. **Outbound Internet**:
   - All spoke traffic routes to Azure Firewall (via UDR)
   - Firewall applies application/network rules
   - NATs to Firewall public IP

5. **Cross-Environment Traffic**:
   - Firewall rules control inter-environment communication
   - By default, environments are isolated
   - Modify firewall rules to allow specific cross-environment flows

## VM Sizing by Environment

The configuration uses cost-optimized VM sizes based on environment:

| Environment | Web Tier | App Tier | DB Tier |
|-------------|----------|----------|---------|
| **Dev** | Standard_B2s | Standard_B2s | Standard_B2ms |
| **UAT** | Standard_D2s_v5 | Standard_D2s_v5 | Standard_E2s_v5 |
| **Prod** | Standard_D4s_v5 | Standard_D4s_v5 | Standard_E4s_v5 |

Additional DB disk:
- Dev: No additional disk
- UAT: 512GB StandardSSD_LRS
- Prod: 1024GB Premium_LRS

## Customization

### Adding More Environments

To add additional environments (e.g., staging):

1. Update `variables.tf`:
```hcl
variable "environments" {
  default = ["dev", "staging", "uat", "prod"]
}

variable "spoke_vnet_address_spaces" {
  default = {
    # ... existing ...
    staging = {
      vnet_cidr       = "10.4.0.0/16"
      web_subnet_cidr = "10.4.1.0/24"
      app_subnet_cidr = "10.4.2.0/24"
      db_subnet_cidr  = "10.4.3.0/24"
    }
  }
}

variable "vm_sizes" {
  default = {
    # ... existing ...
    staging = {
      web = "Standard_D2s_v5"
      app = "Standard_D2s_v5"
      db  = "Standard_E2s_v5"
    }
  }
}
```

2. Run `terraform apply` - the new environment will be created automatically

### Modifying Firewall Rules

Edit the `azurerm_firewall_policy_rule_collection_group` resource in `main.tf`:
- Add network rules for spoke-to-spoke communication
- Add application rules for allowed FQDNs
- Adjust priorities and actions as needed

### Deploying Without VMs

Set `deploy_vms = false` in `terraform.tfvars` to deploy only the network infrastructure without VMs. This is useful for:
- Establishing the network foundation first
- Cost optimization (VMs are the most expensive component)
- Testing network connectivity separately

## Outputs

After deployment, Terraform provides:
- VNet IDs and names by environment
- Azure Firewall private/public IPs
- Azure Bastion connection information
- VM private IPs by environment and tier (if deployed)
- VM managed identity principal IDs
- NSG and route table IDs by environment
- Architecture summary with detailed information

View outputs:
```bash
terraform output
terraform output architecture_summary
```

## Cost Considerations

Approximate monthly costs (East US region, pay-as-you-go):

**Fixed Costs:**
- Azure Firewall Standard: ~$850/month
- Azure Bastion Standard: ~$140/month
- VNet Peering: Data transfer charges apply
- Public IPs (2x Standard): ~$8/month

**Variable Costs (VMs - if deployed):**
- Dev VMs (3x B2s/B2ms): ~$60/month
- UAT VMs (3x D2s_v5/E2s_v5): ~$250/month
- Prod VMs (3x D4s_v5/E4s_v5): ~$500/month

**Total estimated**: ~$1,800/month (all environments with VMs)

Cost optimization tips:
- Use Azure Firewall Standard instead of Premium if advanced features not needed
- Use Bastion Basic SKU for non-production environments
- Set `deploy_vms = false` for environments not actively used
- Use Azure Reserved Instances for prod VMs (1-3 year commitments)
- Shut down non-prod VMs outside business hours using automation
- Consider smaller VM sizes for dev environment (B-series burstable)

## Security Best Practices

- VMs use SSH key authentication (passwords disabled)
- No public IPs on workload VMs
- All traffic inspected by Azure Firewall
- NSGs implement least-privilege access
- VM managed identities for Azure service authentication
- Bastion provides secure access without exposing VMs
- Environment-based isolation prevents unauthorized cross-environment access
- Separate resource groups per environment for RBAC control

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. Cleanup takes approximately 15-20 minutes.

## Additional Resources

- [Azure Hub-Spoke Network Topology](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall Documentation](https://learn.microsoft.com/en-us/azure/firewall/)
- [Azure Bastion Documentation](https://learn.microsoft.com/en-us/azure/bastion/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

For issues or questions:
- Review Terraform plan output
- Check Azure Activity Log in portal
- Verify network connectivity and NSG rules
- Ensure SSH keys are correctly configured
- Review firewall rules for cross-tier communication

## License

This Terraform configuration is provided as-is for educational and production use.
