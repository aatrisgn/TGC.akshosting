# helm repo add jetstack https://charts.jetstack.io --force-update
# helm install \
#   cert-manager jetstack/cert-manager \
#   --namespace cert-manager \
#   --create-namespace \
#   --version v1.18.2 \
#   --set crds.enabled=true


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.18.2"

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]
}