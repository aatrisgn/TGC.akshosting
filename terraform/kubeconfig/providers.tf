provider "azurerm" {
  features {}
  use_oidc = true
}

provider "azuread" {
  use_oidc  = true
  tenant_id = var.tenant_id
}

provider "helm" {
}