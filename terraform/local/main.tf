resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "slowroad"
    }
  }
}

resource "kubernetes_secret" "slowroad_app" {
  metadata {
    name      = "slowroad-app"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    ADMIN_EMAIL    = var.admin_email
    ADMIN_PASSWORD = var.admin_password
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.9.6"
  namespace        = "argocd"
  create_namespace = true
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"
  namespace  = "argocd"

  depends_on = [helm_release.argocd]

  values = [yamlencode({
    applications = {
      slowroad = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = "https://github.com/TelmanArm/devops-infra.git"
          targetRevision = "develop"
          path           = "k8s/overlays/local"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "slowroad"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]
}
