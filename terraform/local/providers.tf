provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "devops-infra"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "devops-infra"
  }
}