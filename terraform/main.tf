resource "azuread_application" "argocd_ui_appreg" {
  display_name = lower("tgc-akshosting-argocdui-auth")
}

resource "azuread_service_principal" "product_environment_spns" {
  client_id = azuread_application.argocd_ui_appreg.client_id
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "ui-akshosting-${var.environment_type_name}-${local.resource_location_name}"
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
  location            = data.azurerm_resource_group.default_resource_group.location
}

resource "azurerm_user_assigned_identity" "argocd_workload_identity" {
  name                = "ui-argowi-${var.environment_type_name}-${local.resource_location_name}"
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
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
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  tags = {
    environment = "personal"
  }
}

# resource "azurerm_kubernetes_cluster_extension" "argocd_configuration" {
#   name           = "argocd"
#   cluster_id     = azurerm_kubernetes_cluster.aks_cluster.id
#   extension_type = "Microsoft.ArgoCD"
#   release_train  = "Preview"

#   #version = "0.0.7-preview"
#    configuration_settings = {
# #     "workloadIdentity.enable" = true
#      "keydeployWithHightAvailability"                                 = false
#      "namespaceInstall"                                               = false
#      "config-maps.argocd-cmd-params-cm.data.application\\.namespaces" = "default,argocd"
#    }
# }

# az k8s-extension create --resource-group <resource-group> --cluster-name <cluster-name> \
# --cluster-type managedClusters \
# --name argocd \
# --extension-type Microsoft.ArgoCD \
# --auto-upgrade false \
# --release-train preview \
# --version 0.0.7-preview \
# --config deployWithHightAvailability=false \
# --config namespaceInstall=false \
# --config "config-maps.argocd-cmd-params-cm.data.application\.namespaces=namespace1,namespace2"
