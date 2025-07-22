output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_resource_group_name" {
  value = data.azurerm_resource_group.default_resource_group.name
}

output "argocd_ui_client_id" {
  value = azuread_application.argocd_ui_appreg.client_id
}

output "argocd_workload_identiy_id" {
  value = azurerm_user_assigned_identity.argocd_workload_identity.client_id
}