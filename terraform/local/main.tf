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
