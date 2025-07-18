# Terraform Settings Block
terraform {
  required_version = "~>v1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.41"
    }
  }
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-tfdata"
    key            = "dev/terraform.tfstate"
    dynamodb_table = "terraform-tfstate-table"
  }
}

# Terraform Provider Block
provider "aws" {
  region  = var.aws_region
  profile = "default"
}