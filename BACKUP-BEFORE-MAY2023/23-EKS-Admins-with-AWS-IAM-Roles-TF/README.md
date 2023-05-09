---
title: EKS Admins with IAM Roles using Terraform
description: Learn how to Create EKS Admins with IAM Roles using Terraform
---

## Step-01: Introduction
### All the below steps we implement using Terraform
1. Create IAM Role with inline policy with EKS Full access.
2. Also Add Trust relationships policy in the same IAM Role
3. Create IAM Group with inline IAM Policy with `sts:AssumeRole`
4. Create IAM Group and associate the IAM Group policy
5. Create IAM User and associate to IAM Group
6. Test EKS Cluster access using credentials generated using `aws sts assume-role` and `kubectl`
7. Test EKS Cluster Dashboard access using `AWS Switch Role` concept via AWS Management Console

## Step-02: Create IAM Role with IAM STS Assume Role Trust Policy and IAM EKS Full Access Policy
- **File:** c9-01-iam-role-eksadmins.tf
```t

# Resource: AWS IAM Role
resource "aws_iam_role" "eks_admin_role" {
  name = "${local.name}-eks-admin-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
  inline_policy {
    name = "eks-full-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "iam:ListRoles",
            "eks:*",
            "ssm:GetParameter"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }    

  tags = {
    tag-key = "${local.name}-eks-admin-role"
  }
}

```

## Step-03: Create Resource: IAM Group 
- **File:** c9-02-iam-group-and-user-eksadmins.tf
```t
# Resource: AWS IAM Group 
resource "aws_iam_group" "eksadmins_iam_group" {
  name = "${local.name}-eksadmins"
  path = "/"
}
```
## Step-04: Create Resource: IAM Group Policy 
- **File:** c9-02-iam-group-and-user-eksadmins.tf
```t

# Resource: AWS IAM Group Policy
resource "aws_iam_group_policy" "eksadmins_iam_group_assumerole_policy" {
  name  = "${local.name}-eksadmins-group-policy"
  group = aws_iam_group.eksadmins_iam_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Sid    = "AllowAssumeOrganizationAccountRole"
        Resource = "${aws_iam_role.eks_admin_role.arn}"
      },
    ]
  })
}
```
## Step-05: Create Resource: IAM User
- **File:** c9-02-iam-group-and-user-eksadmins.tf
```t
# Resource: AWS IAM User - Basic User (No AWSConsole Access)
resource "aws_iam_user" "eksadmin_user" {
  name = "${local.name}-eksadmin3"
  path = "/"
  force_destroy = true
  tags = local.common_tags
}
```
## Step-06: Create Resource: IAM Group Membership
- **File:** c9-02-iam-group-and-user-eksadmins.tf
```t

# Resource: AWS IAM Group Membership
resource "aws_iam_group_membership" "eksadmins" {
  name = "${local.name}-eksadmins-group-membership"
  users = [
    aws_iam_user.eksadmin_user.name
  ]
  group = aws_iam_group.eksadmins_iam_group.name
}
```

## Step-07: Update Locals Block with IAM Role
- **File:** c7-02-kubernetes-configmap.tf
```t
# Sample Role Format: arn:aws:iam::180789647333:role/hr-dev-eks-nodegroup-role
# Locals Block
locals {
  configmap_roles = [
    {
      #rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.eks_nodegroup_role.name}"
      rolearn = "${aws_iam_role.eks_nodegroup_role.arn}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "${aws_iam_role.eks_admin_role.arn}"
      username = "eks-admin" # Just a place holder name
      groups   = ["system:masters"]
    },    
  ]
  configmap_users = [
    {
      userarn  = "${aws_iam_user.basic_user.arn}"
      username = "${aws_iam_user.basic_user.name}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "${aws_iam_user.admin_user.arn}"
      username = "${aws_iam_user.admin_user.name}"
      groups   = ["system:masters"]
    },    
  ]  
} 
```
## Step-08: Update Kubernetes aws-auth ConfigMap Resource
- **File:** c7-02-kubernetes-configmap.tf
```t
# Resource: Kubernetes Config Map
resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [aws_eks_cluster.eks_cluster  ]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(local.configmap_roles)
    mapUsers = yamlencode(local.configmap_users)    
  }  
}
```
## Step-09: Execute Terraform Commands
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Change Directory
cd 23-EKS-Admins-with-AWS-IAM-Roles-TF/01-ekscluster-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-10: Verify aws-auth ConfigMap after EKS Cluster Creation
```t
# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide

# Verify aws-auth configmap 
kubectl -n kube-system get configmap aws-auth -o yaml

# Observation
1. Verify mapUsers section in aws-auth ConfigMap
2. Verify mapRoles section in aws-auth ConfigMap
```

## Step-11: Create IAM User Login Profile and User Security Credentials
```t
# Set password for hr-dev-eksadmin3 user
aws iam create-login-profile --user-name hr-dev-eksadmin3 --password @EKSUser101 --no-password-reset-required

# Create Security Credentials for IAM User and make a note of them
aws iam create-access-key --user-name hr-dev-eksadmin3

# Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws iam create-access-key --user-name hr-dev-eksadmin3
{
    "AccessKey": {
        "UserName": "hr-dev-eksadmin3",
        "AccessKeyId": "AKIASUF7HC7SULAF7HPV",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2022-03-12T06:27:36+00:00"
    }
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```


## Step-12: Configure hr-dev-eksadmin3 user AWS CLI Profile and Set it as Default Profile
```t
# To list all configuration data
aws configure list

# To list all your profile names
aws configure list-profiles

# Configure aws cli eksadmin1 Profile 
aws configure --profile hr-dev-eksadmin3
AWS Access Key ID: AKIASUF7HC7SULAF7HPV
AWS Secret Access Key: 9H6JJMe9hYRgG/IW6DMabgON1Mdn5hTr2oP5Eb8c
Default region: us-east-1
Default output format: json

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Set default profile
export AWS_DEFAULT_PROFILE=hr-dev-eksadmin3

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "hr-dev-eksadmin3" from hr-dev-eksadmin3 profile, refer below sample output

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S43HKHOD5G",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksadmin3"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```
## Step-13: Assume IAM Role and Configure kubectl 
```t
# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# Assume IAM Role
aws sts assume-role --role-arn "arn:aws:iam::<REPLACE-YOUR-ACCOUNT-ID>:role/eks-admin-role" --role-session-name eksadminsession201
aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/hr-dev-eks-admin-role" --role-session-name eksadminsession201

# GET Values and replace here
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
export AWS_SESSION_TOKEN=RoleSessionToken

## SAMPLE FOR REFERENCE
export AWS_ACCESS_KEY_ID=ASIASUF7HC7SVLASERVB
export AWS_SECRET_ACCESS_KEY=X9jKKYGcM/hpOB4euLwiIfIF/fKlfubkwHL2mwpe
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEK///////////wEaCXVzLWVhc3QtMSJHMEUCIQCVXDXoS38cZUk2Y8+8ZBIXIDUu62UfAlwpJmx2nvuuGAIgNCHsOwd98Ft/+fBx5iDp02z3+uECMXO5XKSUCjcX7Y8qnwIIKBADGgwxODA3ODk2NDczMzMiDGt/4pCN+k6uuB0yACr8AQa8Bk4y48RL0uezeU05sRT+0Sei5qpGA8VLYeBFhbKmBk7OLNaXGZEjcpSYYJLDbvScYwjNyH/jQ+UOv8aFKfHJbdoGWPzSAYu6c8ZT2u30sO3v1sUEE8JrG8OY9QjWVXITskQKER7wdtQq4kV33cLnlmVhcWGOVahADMSZkFb54H7Rvu6ibLfDxNAAB7ELsRz9LFylrWyPuEifJ7QggJSimxzxJKBiPPzYrQxtc6YJXyKM7f0js1l3PCw+lZllWORlv4qD6ti+HC7Fd9ojTCDNZpvzWtRl0S4DsH63iAoUDYNCeIxo8EpKSPbIl33wWZr6Is7+V8q+9fPeQjDC/LCRBjqdAZPSIjZCDYuuMRTxnCd1v8bVAqdXNmG6+ala//txB5OdsNYDR+E45L3FuaHqIK9YV1xKwVYbv9bN8o8C7twMpJzsbbYyQ+exGM3RGwtJfa6+kQemrPkCUa5qrinIVYKd+895UbwPikJxC9nO/qn0tj9UU06ajnUy6dsveNjNqTHVdxG3Rt2tBmTMGakyKHBrxBlhYt/Dz0kCGBZ1nCY=

# Verify current user configured in aws cli
aws sts get-caller-identity

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SULHUW3YCH:eksadminsession201",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-admin-role/eksadminsession201"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 

# Clean-Up kubeconfig
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Describe Cluster
aws eks --region us-east-1 describe-cluster --name hr-dev-eksdemo1 --query cluster.status

# List Kubernetes Nodes
kubectl get nodes
kubectl get pods -n kube-system

# Verify aws-auth configmap after making changes
kubectl -n kube-system get configmap aws-auth -o yaml

# To return to the IAM user, remove the environment variables:
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Verify current user configured in aws cli
aws sts get-caller-identity
Observation: It should switch back to current AWS_DEFAULT_PROFILE hr-dev-eksadmin3

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S43HKHOD5G",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksadmin3"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```

## Step-14: Login as hr-dev-eksadmin1 user AWS Mgmt Console and Switch Roles
- Login to AWS Mgmt Console
  - **Username:** hr-dev-eksadmin1
  - **Password:** @EKSUser101
- Go to EKS Servie: https://console.aws.amazon.com/eks/home?region=us-east-1#
```t
# Error
Error loading clusters
User: arn:aws:iam::180789647333:user/hr-dev-eksadmin1 is not authorized to perform: eks:ListClusters on resource: arn:aws:eks:us-east-1:180789647333:cluster/*
```  
- Click on **Switch Role**
  - **Account:** <YOUR_AWS_ACCOUNT_ID> 
  - **Role:** hr-dev-eks-admin-role
  - **Display Name:** eksadmin-session201
  - Select Color: any color
- Access EKS Cluster -> hr-dev-eksdemo1
  - Overview Tab
  - Workloads Tab
  - Configuration Tab  
- All should be accessible without any issues.


## Step-15: Cleanup - EKS Cluster
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should the user "eksadmin1" from eksadmin1 profile

# Set default profile
export AWS_DEFAULT_PROFILE=default

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-16: Clean-up AWS CLI Profiles
```t
# Clean-up AWS Credentials File
vi /Users/kalyanreddy/.aws/credentials
Remove hr-dev-eksadmin1 creds

# Clean-Up AWS Config File
vi /Users/kalyanreddy/.aws/config 
Remove hr-dev-eksadmin1 profiles

# List Profiles - AWS CLI
aws configure list-profiles
```