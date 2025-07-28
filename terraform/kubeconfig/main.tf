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

resource "kubernetes_namespace" "test" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_deployment" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "MyTestApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "MyTestApp"
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.test.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }
  }
}