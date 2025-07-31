resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "cert-manager"
  }
}

resource "null_resource" "apply_manifest" {
  provisioner "local-exec" {
    command = <<EOF
      if ! kubectl get deployment cert-manager -n cert-manager > /dev/null 2>&1; then
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
      else
        echo "cert-manager already installed. Skipping apply."
      fi
    EOF
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.argocd_namespace.metadata.0.name
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

resource "kubernetes_manifest" "letsencrypt_clusterissuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name = "letsencrypt-staging"
      namespace = "streetcroquet"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = "asger.thyregod@gmail.com"
        profile = "tlsserver"
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
  depends_on = [ helm_release.cert_manager ]
}

resource "kubernetes_manifest" "argo_cert_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name = "letsencrypt-staging"
      namespace = "argocd"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = "asger.thyregod@gmail.com"
        profile = "tlsserver"
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
  depends_on = [ helm_release.cert_manager ]
}