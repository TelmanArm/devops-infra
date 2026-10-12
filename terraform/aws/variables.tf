variable "region" {
  description = "AWS region"
  type = string
  default= "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type = string
  default = "devops-infra"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type = string
  default = "1.35"
}

variable "namespace" {
  description = "namespace the app runs in"
  type = string
  default = "slowroad"
}

variable "admin_email" {
  type = string
}

variable "admin_password" {
  type = string
  sensitive = true
}