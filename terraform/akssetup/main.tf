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
#Enable logging
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
  #http_application_routing_enabled = true

  # web_app_routing {
  #   default_nginx_controller = "AnnotationControlled"
  #   dns_zone_ids             = []
  #   web_app_routing_identity = [
  #   {
  #     client_id                 = "c8fc8886-b149-4750-ac67-56809ed9c003"
  #     object_id                 = "967b3f8d-9e30-4c05-9e4b-a07f42f39e29"
  #     user_assigned_identity_id = "/subscriptions/***/resourcegroups/rg-akshosting-dynamic-dev-west-europe/providers/Microsoft.ManagedIdentity/userAssignedIdentities/webapprouting-aks-akshosting-dev-westeurope"
  #   },
  #   ]
  # }


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

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.shared_log_analytic_workspace.id
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
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = "Standard_D2as_v5"
  node_count            = 1
  auto_scaling_enabled = true
  max_count = 5
  priority = "Spot"
  eviction_policy = "Delete"
  spot_max_price = "-1"
  node_labels = {
    "kubernetes.azure.com/scalesetpriority": "spot"
  }
  node_taints = [ "kubernetes.azure.com/scalesetpriority=spot:NoSchedule" ]

  tags = {
    Environment = "Production"
  }
}
