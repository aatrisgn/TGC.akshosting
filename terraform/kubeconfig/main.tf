resource "azuread_application" "argocd_wi_appreg" {
  display_name = lower("tgc-akshosting-argocdwi-auth")
}

resource "azuread_application" "argocd_ui_appreg" {
  display_name = lower("tgc-akshosting-argocduig-auth")
}

resource "azuread_service_principal" "product_environment_spns" {
  client_id = azuread_application.argocd_ui_appreg.client_id
}

resource "azuread_application_redirect_uris" "example_web" {
  application_id = azuread_application.argocd_ui_appreg.id
  type           = "Web"

  redirect_uris = [
    "https://${azurerm_public_ip.aks_public_ip.ip_address}/auth/callback",
  ]
}

resource "azuread_application_redirect_uris" "example_public" {
  application_id = azuread_application.argocd_ui_appreg.id
  type           = "PublicClient"

  redirect_uris = [
    "http://localhost:8085/auth/callback"
  ]
}

resource "azurerm_public_ip" "aks_public_ip" {
  name                = "pip-akshosting-argocdui-public-ip"
  location            = data.azurerm_resource_group.default_resource_group.location
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}

resource "null_resource" "apply_manifest" {
  provisioner "local-exec" {
    command = <<EOF
      if ! kubectl get deployment argocd-server -n argocd > /dev/null 2>&1; then
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      else
        echo "Argo CD already installed. Skipping apply."
      fi
    EOF
  }
}

resource "kubernetes_service" "argocd_loadbalancer" {
  metadata {
    name = "argocd-server-lb"
    namespace = kubernetes_namespace.argocd_namespace.metadata.0.name
    labels = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/name" = "argocd-server"
      "app.kubernetes.io/part-of" = "argocd"
    }
    annotations = {
      "service.beta.kubernetes.io/azure-pip-name" = azurerm_public_ip.aks_public_ip.name
    }
  }
  spec {
    port {
      name = "http"
      port        = 80
      target_port = 8080
      protocol = "TCP"
    }
    port {
      name = "https"
      port        = 443
      target_port = 8080
      protocol = "TCP"
    }
    type = "LoadBalancer"
    selector = {
      "app" = "azure-load-balancer"
    }
  }
}

#kubectl -n argocd expose service argocd-server --type LoadBalancer --name argocd-server-lb --port 80,443 --target-port 8080

# apiVersion: v1
# kind: Service
# metadata:
#   annotations:
#     service.beta.kubernetes.io/azure-load-balancer-resource-group: <node resource group name>
#     service.beta.kubernetes.io/azure-pip-name: myAKSPublicIP
#   name: azure-load-balancer
# spec:
#   type: LoadBalancer
#   ports:
#   - port: 80
#   selector:
#     app: azure-load-balancer