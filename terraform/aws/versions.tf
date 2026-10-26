terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "telman-devops-infra-tfstate"
    key          = "aws/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~>3.1"
    }
  }
}
