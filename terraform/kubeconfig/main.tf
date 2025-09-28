resource "azuread_application" "argocd_wi_appreg" {
  display_name = lower("tgc-akshosting-argocdwi-auth")
}

resource "azuread_application" "argocd_ui_appreg" {
  display_name = lower("tgc-akshosting-argocd-ui-auth") 

  web {
    redirect_uris = [
    "https://${azurerm_public_ip.aks_public_ip.ip_address}/auth/callback",
    "https://argo.dev.tgcportal.com/auth/callback",
    "https://argocd.tgcportal.com/auth/callback",
    ]
  }

  public_client {
    redirect_uris = ["http://localhost:8085/auth/callback"]
  }

  #This should be changed at some point
  lifecycle {
    ignore_changes = [ required_resource_access ]
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    resource_access {
      id = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read.All"]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "product_environment_spns" {
  client_id = azuread_application.argocd_ui_appreg.client_id
}

resource "azuread_application_federated_identity_credential" "example" {
  application_id = azuread_application.argocd_ui_appreg.id
  display_name   = "argocd-ui"
  description    = "Credentials for ArgoCD UI integration"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = data.azurerm_kubernetes_cluster.example.oidc_issuer_url
  subject        = "system:serviceaccount:argocd:argocd-server"
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

resource "null_resource" "patch_argocd_deployment" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl patch deployment argocd-server \
        -n argocd \
        -p '{"spec": {"template": {"metadata":{"labels":{"azure.workload.identity/use":"true"}}}}}'
    EOT
  }
}

resource "null_resource" "patch_argocd_service_account" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl patch serviceaccount argocd-server \
        -n argocd \
        -p '{"metadata":{"annotations":{"azure.workload.identity/client-id":"${azuread_application.argocd_ui_appreg.client_id}"}}}'
    EOT
  }
}

resource "null_resource" "patch_argocd_configmap" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl patch configmap argocd-cm \
        -n argocd \
        --type merge \
        -p '{
          "data": {
            "url": "https://argocd.tgcportal.com/",
            "oidc.config": "name: Azure\nissuer: https://login.microsoftonline.com/${var.tenant_id}/v2.0\nclientID: ${azuread_application.argocd_ui_appreg.client_id}\nazure:\n  useWorkloadIdentity: true\nrequestedIDTokenClaims:\n  groups:\n    essential: false\n    value: \"SecurityGroup\"\nrequestedScopes:\n  - openid\n  - profile\n  - email"
          }
        }'
    EOT
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

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name = "argocd-ingress"
    namespace = "argocd"
    annotations = {
      "cert-manager.io/issuer": "letsencrypt-staging"
      "nginx.ingress.kubernetes.io/force-ssl-redirect"= "true"
      "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
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
                name = "https"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [ module.cert_manager ]
}