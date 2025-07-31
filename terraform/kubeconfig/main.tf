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

resource "azurerm_public_ip" "aks_public_ip_02" {
  name                = "pip-akshosting-argocdui-public-ip-02"
  location            = data.azurerm_resource_group.default_resource_group.location
  resource_group_name = data.azurerm_resource_group.default_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "kubernetes_namespace" "streetcroquet_namespace" {
  metadata {
    name = "streetcroquet"
  }
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

module "nginx_controller" {
  source = "./modules/nginx_controller"
  
  public_ip_name = azurerm_public_ip.aks_public_ip.name
  public_ip_resource_group = azurerm_public_ip.aks_public_ip.resource_group_name
}

module "cert_manager" {
  source = "./modules/cert_manager"
}

resource "kubernetes_deployment" "aks_helloworld_one" {
  metadata {
    name = "aks-streetcroquet"
    namespace = kubernetes_namespace.streetcroquet_namespace.metadata.0.name
    labels = {
      app = "aks-streetcroquet"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "aks-streetcroquet"
      }
    }

    template {
      metadata {
        labels = {
          app = "aks-streetcroquet"
        }
      }

      spec {
        container {
          name  = "aks-streetcroquet"
          image = "tgclzdevacr.azurecr.io/streetcroquetdk:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "aks_helloworld_one" {
  metadata {
    name = "aks-streetcroquet"
    namespace = kubernetes_namespace.streetcroquet_namespace.metadata.0.name
  }

  spec {
    selector = {
      app = "aks-streetcroquet"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "hello_world_ingress" {
  metadata {
    name = "streetcroquet-ingress"
    namespace = kubernetes_namespace.streetcroquet_namespace.metadata.0.name
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"  = "false"
      "cert-manager.io/cluster-issuer": "streetcrocketcertissuer"
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
        secret_name = "dev-streetcrocket-tls"
        hosts = ["dev.streetcrocket.com"]
      }
    rule {
      host = "dev.streetcrocket.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "aks-streetcroquet"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name = "argocd-ingress"
    namespace = "argocd"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"  = "false"
      #       "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
#       "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
#       "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "argo.dev.tgcportal.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [ module.cert_manager ]
}