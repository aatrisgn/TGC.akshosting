locals {
  resource_location_name = replace(data.azurerm_resource_group.default_resource_group.location, " ", "-")
}