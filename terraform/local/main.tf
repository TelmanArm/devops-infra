resource "kubernetes_secret" "slowroad_app" {
  metadata {
    name      = "slowroad-app"
    namespace = var.namespace
  }

  data = {
    ADMIN_EMAIL    = var.admin_email
    ADMIN_PASSWORD = var.admin_password
  }
}
