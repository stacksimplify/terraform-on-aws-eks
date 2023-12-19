# Datasource: 
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.id
}

# Terraform Kubernetes Provider
provider "kubernetes" {
  host = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
}

# Resource: Kubernetes Namespace fp-ns-app1
resource "kubernetes_namespace_v1" "fp_ns_app1" {
  metadata {
    name = "fp-ns-app1"
  }
}

# Resource: EKS Fargate Profile
resource "aws_eks_fargate_profile" "fargate_profile_apps" {
  cluster_name           = aws_eks_cluster.eks_cluster.id
  fargate_profile_name   = "${local.name}-fp-ns-app1"
  pod_execution_role_arn = aws_iam_role.fargate_profile_role.arn
  subnet_ids = module.vpc.private_subnets
  selector {
    #namespace = "fp-ns-app1"
    namespace = kubernetes_namespace_v1.fp_ns_app1.metadata[0].name 
  }
}


# Outputs: Fargate Profile for fp-ns-app1 Namespace
output "fp_ns_app1_fargate_profile_arn" {
  description = "Fargate Profile ARN"
  value = aws_eks_fargate_profile.fargate_profile_apps.arn 
}

output "fp_ns_app1_fargate_profile_id" {
  description = "Fargate Profile ID"
  value = aws_eks_fargate_profile.fargate_profile_apps.id 
}

output "fp_ns_app1_fargate_profile_status" {
  description = "Fargate Profile Status"
  value = aws_eks_fargate_profile.fargate_profile_apps.status
}
