# Terraform Remote State Datasource
/*
data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../../08-AWS-EKS-Cluster-Basics/01-ekscluster-terraform-manifests/terraform.tfstate"
   }
}
*/
# Terraform Remote State Datasource - Remote Backend AWS S3
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-eks"
    key    = "dev/eks-cluster/terraform.tfstate"
    region = "us-east-1" 
  }
}
