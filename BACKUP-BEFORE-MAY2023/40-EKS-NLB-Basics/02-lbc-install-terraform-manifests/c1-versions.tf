# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.12"
     }
    helm = {
      source = "hashicorp/helm"
      #version = "2.5.1"
      version = "~> 2.5"
    }
    http = {
      source = "hashicorp/http"
      #version = "2.1.0"
      version = "~> 2.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.11"
    }      
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-on-aws-eks"
    key    = "dev/aws-lbc/terraform.tfstate"
    region = "us-east-1" 

    # For State Locking
    dynamodb_table = "dev-aws-lbc"    
  }     
}

# Terraform AWS Provider Block
provider "aws" {
  region = var.aws_region
}

# Terraform HTTP Provider Block
provider "http" {
  # Configuration options
}