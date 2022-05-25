# Fargate Profile Outputs
output "fargate_profile_arn" {
  description = "Fargate Profile ARN"
  value = aws_eks_fargate_profile.fargate_profile.arn 
}

output "fargate_profile_id" {
  description = "Fargate Profile ID"
  value = aws_eks_fargate_profile.fargate_profile.id 
}

output "fargate_profile_status" {
  description = "Fargate Profile Status"
  value = aws_eks_fargate_profile.fargate_profile.status
}