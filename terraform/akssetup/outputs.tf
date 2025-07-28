output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_resource_group_name" {
  value = data.azurerm_resource_group.default_resource_group.name
}

output "aks_host_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}