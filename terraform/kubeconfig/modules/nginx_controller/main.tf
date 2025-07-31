resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-basic"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.7.1"

  set = [
    {
      name  = "controller.replicaCount"
      value = 2
    },
    {
      name  = "controller.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "controller.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "controller.image.image"
      value = "ingress-nginx/controller"
    },
    {
      name  = "controller.image.tag"
      value = "v1.8.1"
    },
    {
      name  = "controller.image.digest"
      value = ""
    },
    {
      name  = "controller.admissionWebhooks.patch.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
      value = "/healthz"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-pip-name"
      value = var.public_ip_name
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
      value = var.public_ip_resource_group
    },
    {
      name  = "controller.service.externalTrafficPolicy"
      value = "Local"
    },
    {
      name  = "controller.admissionWebhooks.patch.image.registry"
      value = "tgclzdevacr.azurecr.io"
    },
    {
      name  = "controller.admissionWebhooks.patch.image.image"
      value = "ingress-nginx/kube-webhook-certgen"
    },
    {
      name  = "controller.admissionWebhooks.patch.image.tag"
      value = "v20230407"
    },
    {
      name  = "controller.admissionWebhooks.patch.image.digest"
      value = ""
    },
    {
      name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "defaultBackend.image.registry"
      value = "tgclzdevacr.azurecr.io" 
    },
    {
      name  = "defaultBackend.image.image"
      value = "defaultbackend-amd64"
    },
    {
      name  = "defaultBackend.image.tag"
      value = "1.5"
    },
    {
      name  = "defaultBackend.image.digest"
      value = ""
    }
  ]
}