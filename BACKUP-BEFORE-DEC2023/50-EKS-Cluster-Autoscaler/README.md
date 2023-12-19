---
title: AWS EKS Cluster Autoscaler with Terraform
description: Learn to automate AWS EKS Kubernetes Cluster Autoscaler with Terraform
---

## Step-01: Introduction
- Install Cluster Autoscaler for AWS EKS Cluster

## Step-02: Project-01: Public and Private Node Groups
- **Project Folder:** 01-ekscluster-terraform-manifests
- c5-07-eks-node-group-public.tf
- c5-08-eks-node-group-private.tf
- **Important Note:** Node groups with Auto Scaling groups tags. The Cluster - Autoscaler requires the following tags on your Auto Scaling groups so that they can be auto-discovered.
- Add Cluster Autoscaler tags in Node Groups
```t
  tags = {
    Name = "Public-Node-Group"
    # Cluster Autoscaler Tags
    "k8s.io/cluster-autoscaler/${local.eks_cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "TRUE"	
  }
```

## Step-03: Project-01: Give Autoscaling access to EKS Node Group Role
- **Project Folder:** 01-ekscluster-terraform-manifests
- **File Name:** c5-04-iamrole-for-eks-nodegroup.tf
```t
# Autoscaling Full Access
resource "aws_iam_role_policy_attachment" "eks-Autoscaling-Full-Access" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.eks_nodegroup_role.name
}
```

## Step-04: Project-01: Execute Terraform Commands
```t
# Change Directory
cd 01-ekscluster-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-05: Project-02: Review Terraform Manifests
- **Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
1. c1-versions.tf
  - Create DynamoDB Table `dev-eks-cluster-autoscaler`
2. c2-remote-state-datasource.tf
3. c3-01-generic-variables.tf
4. c3-02-local-values.tf

## Step-06: c4-01-cluster-autoscaler-iam-policy-and-role.tf
- **Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
```t
# Resource: IAM Policy for Cluster Autoscaler
resource "aws_iam_policy" "cluster_autoscaler_iam_policy" {
  name        = "${local.name}-AmazonEKSClusterAutoscalerPolicy"
  path        = "/"
  description = "EKS Cluster Autoscaler Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DescribeInstanceTypes"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
})
}

# Resource: IAM Role for Cluster Autoscaler
## Create IAM Role and associate it with Cluster Autoscaler IAM Policy
resource "aws_iam_role" "cluster_autoscaler_iam_role" {
  name = "${local.name}-cluster-autoscaler"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "cluster-autoscaler"
  }
}


# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.cluster_autoscaler_iam_policy.arn 
  role       = aws_iam_role.cluster_autoscaler_iam_role.name
}

output "cluster_autoscaler_iam_role_arn" {
  description = "Cluster Autoscaler IAM Role ARN"
  value = aws_iam_role.cluster_autoscaler_iam_role.arn
}

```

## Step-07: c4-02-cluster-autoscaler-helm-provider.tf
- **Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
```t
# Datasource: EKS Cluster Auth 
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

# HELM Provider
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
```

## Step-08: c4-03-cluster-autoscaler-install.tf
- **Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
```t
# Install Cluster Autoscaler using HELM

# Resource: Helm Release 
resource "helm_release" "cluster_autoscaler_release" {
  depends_on = [aws_iam_role.cluster_autoscaler_iam_role ]            
  name       = "${local.name}-ca"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  namespace = "kube-system"   

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = data.terraform_remote_state.eks.outputs.cluster_id
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.cluster_autoscaler_iam_role.arn}"
  }
  # Additional Arguments (Optional) - To Test How to pass Extra Args for Cluster Autoscaler
  #set {
  #  name = "extraArgs.scan-interval"
  #  value = "20s"
  #}    
   
}
```

## Step-09: c4-04-cluster-autoscaler-outputs.tf
- **Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
```t
# Helm Release Outputs
output "cluster_autoscaler_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.cluster_autoscaler_release.metadata
}
```

## Step-10: Project-02: Execute Terraform Commands
```t
# Change Directory
cd 02-cluster-autoscaler-install-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-11: Verify Kubernetes Resources
```t
# List Pods
kubectl -n kube-system get pods

# Verify Logs
kubectl -n kube-system logs -f $(kubectl -n kube-system get pods | egrep -o 'hr-dev-ca-aws-cluster-autoscaler-[A-Za-z0-9-]+')

# List Service Account
kubectl -n kube-system get sa
kubectl -n kube-system describe sa cluster-autoscaler 
Observation: 
1. Review Annotations section for IAM Role annotated on Kubernetes Service Account
2. Sample (Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::180789647333:role/hr-dev-cluster-autoscaler)

# List Config Maps
kubectl -n kube-system get cm 
kubectl -n kube-system describe cm cluster-autoscaler-status

# ConfigMap that Cluster Autoscaler writes	
kubectl -n kube-system get cm cluster-autoscaler-status -o yaml
```

## Step-12: Don't Clean-Up EKS Cluster and Cluster Autoscaler
- Dont destroy the Terraform Projects in below two folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 02-cluster-autoscaler-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Destroy  Cluster Autoscaler
# Change Directroy
cd 02-cluster-autoscaler-install-terraform-manifests

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

## References
- [Cluster Autoscaler with Helm](https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler)
- https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
- https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#aws---using-auto-discovery-of-tagged-instance-groups
- https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca
