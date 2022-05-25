# Fargate Profile Role ARN Output
output "fargate_profile_iam_role_arn" {
  description = "Fargate Profile IAM Role ARN"
  value = aws_iam_role.fargate_profile_role.arn 
}

# Fargate Profile Outputs - kube-system Namespace
/*
output "kube_system_fargate_profile_arn" {
  description = "Fargate Profile ARN"
  value = aws_eks_fargate_profile.fargate_profile_kube_system.arn 
}

output "kube_system_fargate_profile_id" {
  description = "Fargate Profile ID"
  value = aws_eks_fargate_profile.fargate_profile_kube_system.id 
}

output "kube_system_fargate_profile_status" {
  description = "Fargate Profile Status"
  value = aws_eks_fargate_profile.fargate_profile_kube_system.status
}
*/