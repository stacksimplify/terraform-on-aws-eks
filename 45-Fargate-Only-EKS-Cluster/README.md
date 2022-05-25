---
title: AWS Fargate Only EKS Cluster with Terraform
description: Learn to create AWS Fargate Only EKS Cluster with Terraform
---

## Step-01: Introduction
1. Create EKS Cluster to run on AWS Fargate
2. Run AWS Load Balancer Controller on AWS Fargate
3. Run Kubernetes External DNS on AWS Fargate
4. Run 3 Sample Apps on AWS Fargate 
5. Test end to end

## Step-02: Project-01: Review Terraform manifests
- **Project Folder:** 01-ekscluster-terraform-manifests
1. c1-versions.tf
2. c2-01-generic-variables.tf
3. c2-02-local-values.tf
4. c3-01-vpc-variables.tf
5. c3-02-vpc-module.tf
6. c3-03-vpc-outputs.tf
7. c4-01-eks-variables.tf
8. c4-02-eks-outputs.tf
9. c4-03-iamrole-for-eks-cluster.tf
10. c4-04-eks-cluster.tf
11. c5-01-iam-oidc-connect-provider-variables.tf
12. c5-02-iam-oidc-connect-provider.tf
13. eks.auto.tfvars
14. terraform.tfvars
15. vpc.auto.tfvars

## Step-03: c4-05-fargate-profile-iam-role-and-policy.tf
- **Project Folder:** 01-ekscluster-terraform-manifests
```t
# Resource: IAM Role for EKS Fargate Profile
resource "aws_iam_role" "fargate_profile_role" {
  name = "${local.name}-eks-fargate-profile-role"

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

# Fargate Profile Role ARN Output
output "fargate_profile_iam_role_arn" {
  description = "Fargate Profile IAM Role ARN"
  value = aws_iam_role.fargate_profile_role.arn 
}
```
## Step-04: c4-06-fargate-profile-kube-system-namespace.tf
- **Project Folder:** 01-ekscluster-terraform-manifests
```t
# Resource: EKS Fargate Profile
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


# Outputs: Fargate Profile for kube-system Namespace
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

```
## Step-05: c4-07-fargate-profile-default-namespace.tf
- **Project Folder:** 01-ekscluster-terraform-manifests
```t
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

```
## Step-06: c4-08-fargate-profile-fp-ns-app1-namespace.tf
- **Project Folder:** 01-ekscluster-terraform-manifests
```t
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
    namespace = "fp-ns-app1"
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

```

## Step-07: Execute Terraform Commands to Create EKS Cluster
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

## Step-08: Configure kubeconfig and List Fargate Profiles 
```t
# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide

# List Fargate Profiles
aws eks list-fargate-profiles --cluster=hr-dev-eksdemo1
```

## Step-09: Patch CoreDNS Pod in kube-system to run on EKS Fargate Profile
```t
# Verify Pods 
kubectl -n kube-system get pods
Observation: Should see coredns pods in pending state

# Run the following command to remove the eks.amazonaws.com/compute-type : ec2 annotation from the CoreDNS pods.
kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'

# Delete & Recreate CoreDNS Pods so that they can get scheduled on Fargate 
kubectl rollout restart -n kube-system deployment coredns

# Verify Pods 
kubectl -n kube-system get pods
Observation: 
1. Wait for a minute or two
2. Should see coredns pods in Running state

# Verify Worker Nodes
kubectl get nodes
Observation: Should see two Fargate nodes related to CoreDNS running
```

## Step-10: Project-02: AWS Load Balancer Controller run on AWS Fargate
- **Project Folder:** 02-lbc-install-terraform-manifests
- Execute Terraform Commands & Verify
```t
# Change Directory 
cd 02-lbc-install-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify LBC Deployment & Pods in kube-system namespace
kubectl -n kube-system get pods
kubectl -n kube-system get deploy
```

## Step-11: Project-03: External DNS Controller run on AWS Fargate
- **Project Folder:** 03-externaldns-install-terraform-manifests
- Execute Terraform Commands & Verify
```t
# Change Directory 
cd 03-externaldns-install-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify External DNS Deployment & Pods in default Namespace
kubectl get pods
kubectl get deploy
```

## Step-12: Project-04: Sample Apps Run on AWS Fargate
- **Project Folder:** 04-run-on-fargate-terraform-manifests
- Execute Terraform Commands & Verify
```t
# Change Directory 
cd 04-run-on-fargate-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify Sample Apps Deployment & Pods in fp-ns-app1 namespace
kubectl -n fp-ns-app1 get pods
kubectl -n fp-ns-app1 get deploy

# Access Application
http://fargate-profile-demo-501.stacksimplify.com
http://fargate-profile-demo-501.stacksimplify.com/app1/index.html
http://fargate-profile-demo-501.stacksimplify.com/app2/index.html
```

## Step-13: Verify all the pods on EKS Cluster using AWS Mgmt Console
- Go to Services -> Elastic Kubernetes Service -> Clusters -> hr-dev-eksdemo1
- In **Resources** Tab
- Under **Workloads**, click on **Pods** and verify

## Step-14: Clean-Up EKS Cluster, LBC Controller, ExternalDNS and Fargate Profile
- Destroy the Terraform Projects in below four folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-lbc-install-terraform-manifests
- **Terraform Project Folder:** 03-externaldns-install-terraform-manifests
- **Terraform Project Folder:** 04-run-on-fargate-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 04-run-on-fargate-terraform-manifests
  - 03-externaldns-install-terraform-manifests
  - 02-lbc-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Delete Fargate Profile
# Change Directory
cd 04-run-on-fargate-terraform-manifests

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


## References
- [Fargate Get Started](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html)


