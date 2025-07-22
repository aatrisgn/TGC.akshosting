terraform {
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.0"
    }

     azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4.0"
    }
  }
}
