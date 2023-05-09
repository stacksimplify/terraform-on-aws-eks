---
title: AWS EKS Kubernetes EFS CSI Driver with Terraform
description: Learn to Automate  AWS EKS Kubernetes EFS CSI Driver with Terraform
---

## Step-01: Introduction
- Increase our EKS Cluster Node group size.
- Install AWS EFS CSI Driver using Helm


## Step-02: Create EKS Cluster
### Step-02-01: c5-08-eks-node-group-private.tf
- Needs big size Node Group for EFS CSI Controller to run
```t
# Before Change
  instance_types = ["t3.medium"]
  scaling_config {
    desired_size = 1
    min_size     = 1    
    max_size     = 2
  }

# After Change
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    min_size     = 2    
    max_size     = 3
  }
```
### Step-02-02: Project-01: Execute Terraform Commands
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

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```
## Step-03: Project-02: Review Terraform Manifests
- **Project Folder:** 02-efs-install-terraform-manifests
1. c1-versions.tf
  - Create new DynamoDB Table `dev-efs-csi`
2. c2-remote-state-datasource.tf
3. c3-01-generic-variables.tf
4. c3-02-local-values.tf

## Step-04: c4-01-efs-csi-datasources.tf
- **Project Folder:** 02-efs-install-terraform-manifests
```t
# Datasource: EFS CSI IAM Policy get from EFS GIT Repo (latest)
data "http" "efs_csi_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

output "efs_csi_iam_policy" {
  value = data.http.efs_csi_iam_policy.body
}
```

## Step-05: c4-02-efs-csi-iam-policy-and-role.tf
- **Project Folder:** 02-efs-install-terraform-manifests
```t
# Resource: Create EFS CSI IAM Policy 
resource "aws_iam_policy" "efs_csi_iam_policy" {
  name        = "${local.name}-AmazonEKS_EFS_CSI_Driver_Policy"
  path        = "/"
  description = "EFS CSI IAM Policy"
  policy = data.http.efs_csi_iam_policy.body
}

output "efs_csi_iam_policy_arn" {
  value = aws_iam_policy.efs_csi_iam_policy.arn 
}

# Resource: Create IAM Role and associate the EFS IAM Policy to it
resource "aws_iam_role" "efs_csi_iam_role" {
  name = "${local.name}-efs-csi-iam-role"

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
            "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "efs-csi"
  }
}

# Associate EFS CSI IAM Policy to EFS CSI IAM Role
resource "aws_iam_role_policy_attachment" "efs_csi_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.efs_csi_iam_policy.arn 
  role       = aws_iam_role.efs_csi_iam_role.name
}

output "efs_csi_iam_role_arn" {
  description = "EFS CSI IAM Role ARN"
  value = aws_iam_role.efs_csi_iam_role.arn
}
```

## Step-06: c4-03-efs-helm-provider.tf
- **Project Folder:** 02-efs-install-terraform-manifests
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

## Step-07: c4-04-efs-csi-install.tf
- **Project Folder:** 02-efs-install-terraform-manifests
```t
# Install EFS CSI Driver using HELM

# Resource: Helm Release 
resource "helm_release" "efs_csi_driver" {
  depends_on = [aws_iam_role.efs_csi_iam_role ]            
  name       = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"

  namespace = "kube-system"     

  set {
    name = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver" # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  }       

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.efs_csi_iam_role.arn}"
  }
    
}
```

## Step-08: c4-05-efs-outputs.tf
- **Project Folder:** 02-efs-install-terraform-manifests
```t
# EFS CSI Helm Release Outputs
output "efs_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.efs_csi_driver.metadata
}
```

## Step-09: Project-02: Execute Terraform Commands
```t
# Change Directory 
cd 02-efs-install-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-10: Verify EFS CSI Driver 
```t
# Verify that aws-efs-csi-driver has started (All Pods)
kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=aws-efs-csi-driver"

[or]

# List Deployments
kubectl -n kube-system get deploy

# List DaemonSets
kubectl -n kube-system get ds

# List Pods
kubectl -n kube-system get pods
```

## Step-11: Verify Logs EFS CSI Driver and CSI Nodes
```t
# Verify Logs - EFS CSI Driver
## Containers Running in the Pod efs-csi-controller
### 1. efs-plugin 
### 2. csi-provisioner 
### 3. liveness-probe
kubectl -n kube-system logs -f <POD-NAME> <CONTAINER-NAME>
kubectl -n kube-system logs -f efs-csi-controller-588c66f79f-b5f9d efs-plugin 
kubectl -n kube-system logs -f efs-csi-controller-588c66f79f-b5f9d csi-provisioner 
kubectl -n kube-system logs -f efs-csi-controller-588c66f79f-b5f9d liveness-probe


# Verify Logs - EFS CSI Node
## Containers Running in the Pod efs-csi-node
### 1. efs-plugin 
### 2. csi-driver-registrar 
### 3. liveness-probe

kubectl -n kube-system logs -f <POD-NAME> <CONTAINER-NAME>
kubectl -n kube-system logs -f efs-csi-node-6td7p efs-plugin 
kubectl -n kube-system logs -f efs-csi-node-6td7p csi-driver-registrar 
kubectl -n kube-system logs -f efs-csi-node-6td7p liveness-probe
```
