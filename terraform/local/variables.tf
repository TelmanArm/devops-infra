variable "kube_context" {
  description = "kubectl context to use"
  type        = string
  default     = "devops-infra"
}

variable "namespace" {
  description = "namespace the app runs in"
  type        = string
  default     = "demo"
}

variable "admin_email" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}
