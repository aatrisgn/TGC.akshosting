resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "cert-manager"
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
    apiVersion = "certmanager.k8s.io/v1alpha1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = "asger.thyregod@gmail.com"
        privateKeySecretRef = {
          name = "letsencrypt"
        }
        http01 = {}
      }
    }
  }
  depends_on = [ helm_release.cert_manager ]
}

resource "kubernetes_manifest" "argo_dev_certificate" {
  manifest = {
    apiVersion = "certmanager.k8s.io/v1alpha1"
    kind       = "Certificate"
    metadata = {
      name = "argo-dev-tls"
    }
    spec = {
      secretName = "argo-dev-tls"
      issuerRef = {
        name = "letsencrypt"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "argo.dev.tgcportal.com"
      ]
      acme = {
        config = [
          {
            http01 = {
              ingressClass = "nginx"
            }
            domains = [
              "argo.dev.tgcportal.com"
            ]
          }
        ]
      }
    }
  }
}

