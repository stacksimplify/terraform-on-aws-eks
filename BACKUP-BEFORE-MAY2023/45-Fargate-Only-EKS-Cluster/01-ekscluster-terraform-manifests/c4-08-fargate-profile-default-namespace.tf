# Resource: EKS Fargate Profile
resource "aws_eks_fargate_profile" "fargate_profile_default" {
  cluster_name           = aws_eks_cluster.eks_cluster.id
  fargate_profile_name   = "${local.name}-fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_profile_role.arn
  subnet_ids = module.vpc.private_subnets
  selector {
    namespace = "default"
  }
}


# Outputs: Fargate Profile for default Namespace
output "default_fargate_profile_arn" {
  description = "Fargate Profile ARN"
  value = aws_eks_fargate_profile.fargate_profile_default.arn 
}

output "default_fargate_profile_id" {
  description = "Fargate Profile ID"
  value = aws_eks_fargate_profile.fargate_profile_default.id 
}

output "default_fargate_profile_status" {
  description = "Fargate Profile Status"
  value = aws_eks_fargate_profile.fargate_profile_default.status
}
