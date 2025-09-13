resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "ui-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
  location            = data.azurerm_resource_group.default_resource_group.location
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = data.azurerm_resource_group.default_resource_group.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

#TODO:
#Update app reg accordingly to Entra
#Fix DNS domain for it
# We need to ensure pull access on ACR
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                             = "aks-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  location                         = data.azurerm_resource_group.default_resource_group.location
  resource_group_name              = data.azurerm_resource_group.default_resource_group.name
  dns_prefix                       = "aks-akshosting-${var.environment_type_name}"
  oidc_issuer_enabled              = true
  workload_identity_enabled        = true
  node_resource_group              = "rg-akshosting-dynamic-${var.environment_type_name}-west-europe"

  default_node_pool {
    name            = "default"
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
    auto_scaling_enabled = true
    max_count = 1
    min_count = 1
    upgrade_settings {
      drain_timeout_in_minutes      = 0 
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "personal"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "spot_pool" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = "Standard_B2pls_v2"
  node_count            = 1
  auto_scaling_enabled = true
  max_count = 5
  tags = {
    Environment = "Production"
  }
}
