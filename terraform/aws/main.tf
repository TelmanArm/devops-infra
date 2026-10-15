# app namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "slowroad"
    }
  }

  depends_on = [module.eks]
}

# admin login for the app
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

# argo cd itself
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.9.6"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]
}

# tell argo cd to deploy my chart
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
          targetRevision = "main"
          path           = "charts/slowroad"
          helm           = { valueFiles = ["values-aws.yaml"] }
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