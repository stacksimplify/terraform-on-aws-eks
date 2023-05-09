# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.70"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.7"
    }    
  }
}
