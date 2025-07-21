
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "ui-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  resource_group_name = data.azurerm_resource_group.default_resource_group.names
  location            = data.azurerm_resource_group.default_resource_group.location
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  location            = data.azurerm_resource_group.default_resource_group.location
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
  dns_prefix          = "aks-akshosting-${var.environment_type_name}"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  tags = {
    environment = "personal"
  }
}
