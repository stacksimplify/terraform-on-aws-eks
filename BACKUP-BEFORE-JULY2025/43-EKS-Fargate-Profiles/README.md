---
title: AWS EKS Fargate Profile with Terraform
description: Learn to create AWS EKS Kubernetes Fargate Profiles with Terraform
---
## Step-01: Introduction
- Create AWS EKS Fargate Profile

## Step-02: Review Terraform manifests
- **Project Folder:** 04-fargate-profiles-terraform-manifests
1. c1-versions.tf
   - Create DynamoDB Table `dev-eks-fargate-profile`
2. c2-remote-state-datasource.tf
3. c3-01-generic-variables.tf
4. c4-01-kubernetes-provider.tf

## Step-03: c4-02-kubernetes-namespace.tf
- **Project Folder:** 04-fargate-profiles-terraform-manifests
```t
# Resource: Kubernetes Namespace fp-ns-app1
resource "kubernetes_namespace_v1" "fp_ns_app1" {
  metadata {
    name = "fp-ns-app1"
  }
}
```

## Step-04: c5-01-fargate-profile-iam-role-and-policy.tf
- **Project Folder:** 04-fargate-profiles-terraform-manifests
```t
# Resource: IAM Role for EKS Fargate Profile
resource "aws_iam_role" "fargate_profile_role" {
  name = "${local.name}-eks-fargate-profile-role-apps"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Resource: IAM Policy Attachment to IAM Role
resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_profile_role.name
}
```

## Step-05: c5-02-fargate-profile.tf
- **Project Folder:** 04-fargate-profiles-terraform-manifests
```t
# Resource: EKS Fargate Profile
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_id
  fargate_profile_name   = "${local.name}-fp-app1"
  pod_execution_role_arn = aws_iam_role.fargate_profile_role.arn
  subnet_ids = data.terraform_remote_state.eks.outputs.private_subnets
  selector {
    namespace = "fp-ns-app1"
  }
}
```


## Step-06: c5-03-fargate-profile-outputs.tf
- **Project Folder:** 04-fargate-profiles-terraform-manifests
```t
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
```

## Step-07: Execute Terraform Commands
```t
# Change Directory 
cd 04-fargate-profiles-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```

## Step-08: Verify Fargate Profile using AWS CLI
- [AWS EKS CLI](https://awscli.amazonaws.com/v2/documentation/api/2.1.29/reference/eks/index.html)
```t
# List Fargate Profiles
aws eks list-fargate-profiles --cluster <CLUSTER_NAME>
aws eks list-fargate-profiles --cluster hr-dev-eksdemo1
```
## Step-09: Review aws-auth ConfigMap for Fargate Profiles related Entry
- When AWS Fargate Profile is created on EKS Cluster, `aws-auth` configmap is updated in EKS Cluster with the IAM Role we are using for Fargate Profiles. 
- For additional reference, review file: `43-EKS-Fargate-Profiles/sample-aws-auth-configmap.yaml`
```t
# Review the aws-auth ConfigMap
kubectl -n kube-system get configmap aws-auth -o yaml

## Sample from aws-auth ConfigMap related to Fargate Profile IAM Role
    - groups:
      - system:bootstrappers
      - system:nodes
      - system:node-proxier
      rolearn: arn:aws:iam::180789647333:role/hr-dev-eks-fargate-profile-role-apps
      username: system:node:{{SessionName}}
```

## Step-10: Verify Fargate Profile using AWS Mgmt Console
```t
# Get the current user configured in AWS CLI (EKS Cluster Creator user)
aws sts get-caller-identity

## Sample Output
Kalyans-MacBook-Pro:04-fargate-profiles-terraform-manifests kdaida$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SSJRDGMFBM",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/kalyandev"
}
Kalyans-MacBook-Pro:04-fargate-profiles-terraform-manifests kdaida$ 

# Verify Fargate Profiles via AWS Mgmt Console
1. Login to AWS Mgmt console with same user with which we are created the EKS Cluster. In my casr it is "kalyandev" user
2. Go to Services -> Elastic Kubernetes Services -> Clusters -> hr-dev-eksdemo1
3. Go to "Configuration" Tab -> "Compute Tab"   
4. Review the Fargate profile in "Fargate profiles" section
```


## Step-11: Don't Clean-Up EKS Cluster, LBC Controller, ExternalDNS and Fargate Profile
- Dont destroy the Terraform Projects in below two folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-lbc-install-terraform-manifests
- **Terraform Project Folder:** 03-externaldns-install-terraform-manifests
- **Terraform Project Folder:** 04-fargate-profiles-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 04-fargate-profiles-terraform-manifests
  - 03-externaldns-install-terraform-manifests
  - 02-lbc-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Delete Fargate Profile
# Change Directory
cd 04-fargate-profiles-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve
##############################################################
## Destroy External DNS
# Change Directroy
cd 03-externaldns-install-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve
##############################################################
## Destroy  LBC
# Change Directroy
cd 02-lbc-install-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve
##############################################################
## Destroy EKS Cluster
# Change Directroy
cd 01-ekscluster-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve
##############################################################
```







