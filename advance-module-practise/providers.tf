# Add your subscriptionID, TenantID and service principle credentials accordingly.
provider "azurerm" {
  features {}


}


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.47.0"
    }
  }
}
    