resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "ui-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
  location            = data.azurerm_resource_group.default_resource_group.location
}

#TODO:
#Update app reg accordingly to Entra
#Enable logging
#Fix DNS domain for it
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                      = "aks-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  location                  = data.azurerm_resource_group.default_resource_group.location
  resource_group_name       = data.azurerm_resource_group.default_resource_group.name
  dns_prefix                = "aks-akshosting-${var.environment_type_name}"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  node_resource_group       = "rg-akshosting-dynamic-${var.environment_type_name}-west-europe"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.shared_log_analytic_workspace.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }


  tags = {
    environment = "personal"
  }
}
