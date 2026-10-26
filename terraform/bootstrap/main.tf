# Terraform version and AWS provider requirements
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWS provider configuration (Stockholm region)
provider "aws" {
  region = "eu-north-1"
}

# S3 bucket for Terraform remote state, protected from accidental deletion
resource "aws_s3_bucket" "tfstate" {
  bucket = "telman-devops-infra-tfstate"

  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning to keep state file history
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}