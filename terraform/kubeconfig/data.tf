data "azurerm_resource_group" "default_resource_group" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "example" {
  name                = "aks-akshosting-dev-westeurope"
  resource_group_name = var.resource_group_name
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}