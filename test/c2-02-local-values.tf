# Define Local Values in Terraform
locals {
  owners      = var.business_divsion
  environment = terraform.workspace
  name        = "${var.business_divsion}-${var.environment}"
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    owners      = local.owners
    environment = local.environment
  }
  eks_cluster_name = "${local.name}-${var.cluster_name}"
} 