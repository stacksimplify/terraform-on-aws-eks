# Resource: EKS Fargate Profile for kube-system Apps
/*
resource "aws_eks_fargate_profile" "fargate_profile_kube_system" {
  cluster_name           = aws_eks_cluster.eks_cluster.id
  fargate_profile_name   = "${local.name}-fp-kube-system"
  pod_execution_role_arn = aws_iam_role.fargate_profile_role.arn
  subnet_ids = module.vpc.private_subnets
  selector {
    namespace = "kube-system"
    # Enable the below labels if we want only CoreDNS Pods to run on Fargate from kube-system namespace
    #labels = { 
    #  "k8s-app" = "kube-dns"
    #}
  }
}
*/


# Resource: Kubernetes Namespace fp-ns-app1
resource "kubernetes_namespace_v1" "fp_ns_app1" {
  metadata {
    name = "fp-ns-app1"
  }
}

# Resource: EKS Fargate Profile
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.id
  fargate_profile_name   = "${local.name}-fp-app1"
  pod_execution_role_arn = aws_iam_role.fargate_profile_role.arn
  subnet_ids = module.vpc.private_subnets
  selector {
    namespace = "fp-ns-app1"
  }
  # Ensure that aws-auth Config Map Roles are updated with Fargate Role in it before creating the Fargate Profile
  depends_on = [kubernetes_config_map_v1.aws_auth ] 
}