---
title: Kubernetes Role and Role Binding
description: Kubernetes Role and Role Binding in combination with AWS IAM Role, Group and User on EKS Cluster
---

## Step-01: Introduction
### All the below steps we implement using Terraform
1. Create IAM Role with inline policy with EKS Developer access.
2. Also Add Trust relationships policy in the same IAM Role
3. Create IAM Group with inline IAM Policy with `sts:AssumeRole`
4. Create IAM Group and associate the IAM Group policy
5. Create IAM User and associate to IAM Group
6. Create Kubernetes `ClusterRole` and `ClusterRoleBinding`, in addition create `Role` and `RoleBinding` with full access to `dev namespace` for that Developer User. 
7. Update `aws-auth ConfigMap` with EKS Developer Role in `mapRoles` section
8. Create EKS Cluster
9. Test EKS Cluster access using credentials generated using `aws sts assume-role` and `kubectl`
10. Test EKS Cluster Dashboard access using `AWS Switch Role` concept via AWS Management Console

## Step-02: Create IAM Role with IAM STS Assume Role Trust Policy and IAM EKS Read-Only Access Policy
- **File:** c11-01-iam-role-eksdeveloper.tf
```t
# Resource: AWS IAM Role - EKS Developer User
resource "aws_iam_role" "eks_developer_role" {
  name = "${local.name}-eks-developer-role"

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
    name = "eks-developer-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "iam:ListRoles",
            "ssm:GetParameter",
            "eks:DescribeNodegroup",
            "eks:ListNodegroups",
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AccessKubernetesApi",
            "eks:ListUpdates",
            "eks:ListFargateProfiles",
            "eks:ListIdentityProviderConfigs",
            "eks:ListAddons",
            "eks:DescribeAddonVersions"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }    

  tags = {
    tag-key = "${local.name}-eks-developer-role"
  }
}
```

## Step-03: Create Resource: IAM Group 
- **File:** c11-02-iam-group-and-user-eksdeveloper.tf
```t
# Resource: AWS IAM Group 
resource "aws_iam_group" "eksdeveloper_iam_group" {
  name = "${local.name}-eksdeveloper"
  path = "/"
}

```
## Step-04: Create Resource: IAM Group Policy 
- **File:** c11-02-iam-group-and-user-eksdeveloper.tf
```t

# Resource: AWS IAM Group Policy
resource "aws_iam_group_policy" "eksdeveloper_iam_group_assumerole_policy" {
  name  = "${local.name}-eksdeveloper-group-policy"
  group = aws_iam_group.eksdeveloper_iam_group.name

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
        Resource = "${aws_iam_role.eks_developer_role.arn}"
      },
    ]
  })
}

```
## Step-05: Create Resource: IAM User
- **File:** c11-02-iam-group-and-user-eksdeveloper.tf
```t

# Resource: AWS IAM User 
resource "aws_iam_user" "eksdeveloper_user" {
  name = "${local.name}-eksdeveloper1"
  path = "/"
  force_destroy = true
  tags = local.common_tags
}
```
## Step-06: Create Resource: IAM Group Membership
- **File:** c11-02-iam-group-and-user-eksdeveloper.tf
```t
# Resource: AWS IAM Group Membership
resource "aws_iam_group_membership" "eksdeveloper" {
  name = "${local.name}-eksdeveloper-group-membership"
  users = [
    aws_iam_user.eksdeveloper_user.name
  ]
  group = aws_iam_group.eksdeveloper_iam_group.name
}
```


## Step-07: Create Kubernetes ClusterRole Resource
- **File:** c11-03-k8s-clusterrole-clusterrolebinding.tf
```t
# Resource: k8s Cluster Role
resource "kubernetes_cluster_role_v1" "eksdeveloper_clusterrole" {
  metadata {
    name = "${local.name}-eksdeveloper-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "events", "services"]
    #resources  = ["nodes", "namespaces", "pods", "events", "services", "configmaps", "serviceaccounts"] #Uncomment for additional Testing
    verbs      = ["get", "list"]    
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list"]    
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list"]    
  }  
}

```

## Step-08: Create Kubernetes ClusterRoleBinding Resource
- **File:** c11-03-k8s-clusterrole-clusterrolebinding.tf
```t

# Resource: k8s Cluster Role Binding
resource "kubernetes_cluster_role_binding_v1" "eksdeveloper_clusterrolebinding" {
  metadata {
    name = "${local.name}-eksdeveloper-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksdeveloper_clusterrole.metadata.0.name 
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}
```

## Step-09: Create Namespace dev
- **File:** c11-04-namespaces.tf
```t
# Resource: k8s namespace
resource "kubernetes_namespace_v1" "k8s_dev" {
  metadata {
    name = "dev"
  }
}
```

## Step-10: Create Kubernetes Role Resource
- **File:** c11-05-k8s-role-rolebinding.tf
```t
# Resource: k8s Role
resource "kubernetes_role_v1" "eksdeveloper_role" {
  metadata {
    name = "${local.name}-eksdeveloper-role"
    namespace = "dev"
  }

  rule {
    api_groups     = ["", "extensions", "apps"]
    resources      = ["*"]
    verbs          = ["*"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["*"]
  }
}
```

## Step-11: Create Kubernetes RoleBinding Resource
- **File:** c11-05-k8s-role-rolebinding.tf
```t

# Resource: k8s Role Binding
resource "kubernetes_role_binding_v1" "eksdeveloper_rolebinding" {
  metadata {
    name      = "${local.name}-eksdeveloper-rolebinding"
    namespace = "dev"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.eksdeveloper_role.metadata.0.name 
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}
```
## Step-12: Update Locals Block with IAM Role
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
    {
      rolearn  = "${aws_iam_role.eks_readonly_role.arn}"
      username = "eks-readonly" # Just a place holder name
      #groups   = [ "eks-readonly-group" ]
      # Important Note: The group name specified in clusterrolebinding and in aws-auth configmap groups should be same. 
      groups   = [ "${kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding.subject[0].name}" ]
    },
    {
      rolearn  = "${aws_iam_role.eks_developer_role.arn}"
      username = "eks-developer" # Just a place holder name
      #groups   = [ "eks-developer-group" ]
      # Important Note: The group name specified in clusterrolebinding and in aws-auth configmap groups should be same.       
      groups   = [ "${kubernetes_role_binding_v1.eksdeveloper_rolebinding.subject[0].name}" ]
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
## Step-13: Update Kubernetes aws-auth ConfigMap Resource
- **File:** c7-02-kubernetes-configmap.tf
- Add Resources `kubernetes_cluster_role_binding_v1.eksdeveloper_clusterrolebinding`,
    `kubernetes_role_binding_v1.eksdeveloper_rolebinding` in depends_on Meta-Argument 
```t

# Resource: Kubernetes Config Map
resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [
    aws_eks_cluster.eks_cluster,
    kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding,
    kubernetes_cluster_role_binding_v1.eksdeveloper_clusterrolebinding,
    kubernetes_role_binding_v1.eksdeveloper_rolebinding
      ]
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
## Step-14: Execute Terraform Commands
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Change Directory
cd 25-EKS-DeveloperAccess-IAM-Users/01-ekscluster-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-15: Verify aws-auth ConfigMap after EKS Cluster Creation
```t
# Stop Bastion Host
Login to AWS Mgmt Console -> EC2 -> hr-dev-Bastion-Host -> Instance State -> Stop 

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

## Step-16: Create IAM User Login Profile and User Security Credentials
```t
# Set password for hr-dev-eksdeveloper1 user
aws iam create-login-profile --user-name hr-dev-eksdeveloper1 --password @EKSUser101 --no-password-reset-required

# Create Security Credentials for IAM User and make a note of them
aws iam create-access-key --user-name hr-dev-eksdeveloper1

# Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws iam create-access-key --user-name hr-dev-eksdeveloper1
{
    "AccessKey": {
        "UserName": "hr-dev-eksdeveloper1",
        "AccessKeyId": "AKIASUF7HC7SYIH37PVL",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2022-05-01T07:06:56+00:00"
    }
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```

## Step-17: Configure hr-dev-eksdeveloper1 user AWS CLI Profile and Set it as Default Profile
```t
# To list all configuration data
aws configure list

# To list all your profile names
aws configure list-profiles

# Configure aws cli eksadmin1 Profile 
aws configure --profile hr-dev-eksdeveloper1
AWS Access Key ID: AKIASUF7HC7SXRQN6CFR
AWS Secret Access Key: z3ZrF/cbJe2Oe8i7ud+184ggHOCEJ5m5IFzYqB55
Default region: us-east-1
Default output format: json

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Set default profile
export AWS_DEFAULT_PROFILE=hr-dev-eksdeveloper1

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "hr-dev-eksdeveloper1" from hr-dev-eksdeveloper1 profile, refer below sample output

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SXXKAVQ5R5",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksdeveloper1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```
## Step-18: Assume IAM Role and Configure kubectl and Access Kubernetes Objects which user hr-dev-eksdeveloper1 has access
```t
# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# Assume IAM Role
aws sts assume-role --role-arn "arn:aws:iam::<REPLACE-YOUR-ACCOUNT-ID>:role/<REPLACE-YOUR-ROLE-NAME>" --role-session-name eksadminsession201
aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/hr-dev-eks-developer-role" --role-session-name eksdevsession101

# GET Values and replace here
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
export AWS_SESSION_TOKEN=RoleSessionToken

## SAMPLE FOR REFERENCE
export AWS_ACCESS_KEY_ID=ASIASUF7HC7SUMOZOE27
export AWS_SECRET_ACCESS_KEY=U/Lf3itP39cDnUIpiex/mOTuiblLQxxK2Hz+ojlW
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEGAaCXVzLWVhc3QtMSJHMEUCIBRdy8WD5igET85FHvLD0/KXyeK0xoxDZNEfJW471w+xAiEAywivOprTo8KR/9d4lasoOO5/vzFDGzbwlMjxjALZx5gqnQIIKBADGgwxODA3ODk2NDczMzMiDK6eR4+1U3m6nQQQgyr6Aa/+7ATi1t6yKahwUIAjzGXF6b0H38e3D8Twzt5lecW+WV9nhG8K1DubSEwwe3C1bnKBf9RQd1tJj70dwy2HNUWEFvL1yqKvudWACNf76HNJDZRNZmJ73+c3BqyKBRlSOA5c3Jh1TF4VTPGyJ/JXUFauEmdFT0ULBOySC+YMXMJj2ebqfd8+7jnBbWtdrjfKQWyWfhhKWH+zoLQ1Bikia/jXysg5KtwDAENq5nErDr8LmfIG1DSoOuDxyHQPVuXrUyYLvp3nEHL1a7V0vNg34FnSYg1GvLg6Z3yftccmRT9c9Aea87kgmAnUF4oMubNqA75m/gYUyvx02BkwiuW4kwY6nQGk8JzQJc4mRg4i85viyb0Zmy6iX1kQAokC8KsQMA4SnJCDnsMqOcIo+vvuZ0ehyl8am2KNRN1kh11BQ4hAIM7LSU37YP8cqHj3lxDDLvGZDIKoeHCQ0Fnu7+zRbNlPp1fQ/tccnuLLPSagiPKFNfVk17RhcThy2llcvkjODR7wfaBtSykL5QjHitVWZl0AV6+9Xw0nNW4BaEaQHJ68

# Verify current user configured in aws cli
aws sts get-caller-identity

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SSJZFJQPPD:eksdevsession101",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-developer-role/eksdevsession101"
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

# Verify Kubernetes Nodes
kubectl get nodes

# Verify Deployments
kubectl get deploy -n kube-system

# Verify Pods
kubectl get pods -n kube-system

# Verify Services
kubectl get svc
kubectl get svc -n kube-system
Observation: All the above should pass (pods, services, deployments, nodes etc). 
```

## Step-19: Assume IAM Role and Configure kubectl and Access Kubernetes Objects which user hr-dev-eksdeveloper1 don't have access
```t
# Verify aws-auth configmap
kubectl -n kube-system get configmap aws-auth -o yaml
Observation: Should fail because we didn't access to ConfigMap resources in API Group "" (Core APIs)

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ kubectl -n kube-system get configmap aws-auth -o yaml
Error from server (Forbidden): configmaps "aws-auth" is forbidden: User "eks-developer" cannot get resource "configmaps" in API group "" in the namespace "kube-system"
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 

# Verify Service Accounts
kubectl get sa
kubectl get sa -n kube-system
Observation: Should fail because we didn't access to ServiceAccount resources in API Group "" (Core APIs)

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ kubectl get sa -n kube-system
Error from server (Forbidden): serviceaccounts is forbidden: User "eks-developer" cannot list resource "serviceaccounts" in API group "" in the namespace "kube-system"
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```

## Step-20: Review Sample App that need to be deployed to Dev Namespace - YAML Manifests
- Sample App manifests are created using `YAML` and we can deploy them using `kubectl`
```t
# Change Directory 
cd 25-EKS-DeveloperAccess-IAM-Users/03-app1-kube-manifests

# Review YAML Files
1. 01-Deployment.yaml
2. 02-CLB-LoadBalancer-Service.yaml
3. 03-NodePort-Service.yaml
4. 04-NLB-LoadBalancer-Service.yaml
```

## Step-21: Deploy Sample App to Dev Namespace using IAM User hr-dev-eksdeveloper1
- Sample App manifests are created using `YAML` and we can deploy them using `kubectl`
```t
# Change Directory 
cd 25-EKS-DeveloperAccess-IAM-Users/

# Verify User
aws sts get-caller-identity

## Sample
Kalyans-Mac-mini:25-EKS-DeveloperAccess-IAM-Users kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SSJZFJQPPD:eksdevsession101",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-developer-role/eksdevsession101"
}
Kalyans-Mac-mini:25-EKS-DeveloperAccess-IAM-Users kalyanreddy$ 


# Deploy kube-manifests (YAML Format) to Dev Namespace using hr-dev-eksdeveloper1 user
kubectl apply -f 03-app1-kube-manifests/
Observation: 
1. hr-dev-eksdeveloper1 has full access to Dev Namespace as per Role and RoleBinding we have defined in c11-05-k8s-role-rolebinding.tf
2. We should see a successful creation of Kubernetes Deployment and Services

# Verify Dev Namespace resources using hr-dev-eksdeveloper1 user
kubectl get deploy -n dev
kubectl get pods -n dev
kubectl get svc -n dev

# Access App
http://CLB-DNS
http://NLB-DNS

# Clean-Up - Apps from Dev Namespace 
kubectl delete -f 03-app1-kube-manifests/
```

## Step-22: Review Sample App that need to be deployed to Dev Namespace - Terraform Manifests
- Sample App manifests are created using `TERRAFORM LANGUAGE` and we can deploy them using `Terraform Commands`
```t
# Change Directory 
cd 25-EKS-DeveloperAccess-IAM-Users/04-k8sresources-terraform-manifests

# Review Terraform Config Files
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-deployment.tf
5. c5-kubernetes-loadbalancer-service-clb.tf
6. c6-kubernetes-nodeport-service.tf
7. c7-kubernetes-loadbalancer-service-nlb.tf
```

## Step-23: Deploy Sample App to Dev Namespace using IAM User hr-dev-eksdeveloper1 - Terraform Manifests
- Sample App manifests are created using `TERRAFORM LANGUAGE` and we can deploy them using `Terraform Commands`
```t
# Verify User
aws sts get-caller-identity

## Sample
Kalyans-Mac-mini:25-EKS-DeveloperAccess-IAM-Users kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SSJZFJQPPD:eksdevsession101",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-developer-role/eksdevsession101"
}
Kalyans-Mac-mini:25-EKS-DeveloperAccess-IAM-Users kalyanreddy$ 

# Change Directory 
cd 25-EKS-DeveloperAccess-IAM-Users/04-k8sresources-terraform-manifests

# Deploy Terraform Manifests of Sample App to Dev Namespace using hr-dev-eksdeveloper1 user
terraform init

## ERROR
Kalyans-Mac-mini:04-k8sresources-terraform-manifests kalyanreddy$ terraform init

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Error refreshing state: AccessDenied: Access Denied
	status code: 403, request id: A1FGCJSFAZNG3XHR, host id: lp0Ho4QZPMeEIhVEhRdcbIGWs6ZGVJ9AlV8EmmzOUq0hSrs4hlnsNCVpSEtnbSNk3KialfM4bdQ=
Kalyans-Mac-mini:04-k8sresources-terraform-manifests kalyanreddy$ 
```

## Step-24: Provide S3 and DynamoDB Full Access to hr-dev-eks-developer-role
- We need to provide S3 and DynamoDB Access to role `hr-dev-eks-developer-role` to deploy Apps to Dev Namespace using user `hr-dev-eksdeveloper1` provided if we are using `Remote State Datasource` as S3 Bucket and for `State Locking` if we are uing DynamoDB
- In AWS Mgmt Console, go to Services -> IAM -> Roles -> hr-dev-eks-developer-role
- Add below two policies
  - AmazonS3FullAccess
  - AmazonDynamoDBFullAccess
- We can also automate this by adding below code by updating in  
- **File:** `25-EKS-DeveloperAccess-IAM-Users/01-ekscluster-terraform-manifests/c11-01-iam-role-eksdeveloper.tf`
```t
# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-developrole-s3fullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.eks_developer_role.name
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-developrole-dynamodbfullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.eks_developer_role.name
}
```

## Step-25: Switch to Default AWS CLI Profile 
```t
# To return to the IAM user, remove the environment variables:
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Verify current user configured in aws cli
aws sts get-caller-identity
Observation: It should switch back to current AWS_DEFAULT_PROFILE hr-dev-eksdeveloper1

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S4AEP4ILE2",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksdeveloper1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 

# Set default profile
export AWS_DEFAULT_PROFILE=default

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SSJRDGMFBM",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/kalyandev"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$

```

## Step-26: Apply Changes for hr-dev-eks-developer-role
```t
# Change Directory 
25-EKS-DeveloperAccess-IAM-Users/01-ekscluster-terraform-manifests

# Terraform Commands
terraform plan
terraform apply -auto-approve
```


## Step-27: Deploy Sample App to Dev Namespace using IAM User hr-dev-eksdeveloper1 - Terraform Manifests - After fixing S3 and DynamoDB Access
- We need to again set our AWS CLI profile to STS Assume Role Session
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Set default profile
export AWS_DEFAULT_PROFILE=hr-dev-eksdeveloper1

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "hr-dev-eksdeveloper1" from hr-dev-eksdeveloper1 profile, refer below sample output

# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# Assume IAM Role
aws sts assume-role --role-arn "arn:aws:iam::<REPLACE-YOUR-ACCOUNT-ID>:role/<REPLACE-YOUR-ROLE-NAME>" --role-session-name eksadminsession201
aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/hr-dev-eks-developer-role" --role-session-name eksdevsession103

# GET Values and replace here
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
export AWS_SESSION_TOKEN=RoleSessionToken

## SAMPLE FOR REFERENCE
export AWS_ACCESS_KEY_ID=ASIASUF7HC7SYHUYYMHJ
export AWS_SECRET_ACCESS_KEY=2KJbWzxVypARS3MNIVSxLBZ8Y+JKev7DJhMRfgaS
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEGAaCXVzLWVhc3QtMSJGMEQCIF1KjPD13XQOIzN/Jfvm61DxhTP8g/1I1AFhblVhpOkgAiBfMKAMAHfVYb900w277XusdKDPN0HEf2Lt49KLIckYziqdAggpEAMaDDE4MDc4OTY0NzMzMyIMpxwC7EteevGTrtLfKvoBAZ7CusBdhytrz8RFYauWTw5pINN9BeNAYkEHBHtQ5g1+sNtvi3xT9cfrYEM4/jTYzT8n15+Ne/QXs7Nb6O3aItW0/eZM2UdQGVKgQ0KIQeKXMbWA4Ick3bnLTs5rqWv50V/TC+7KhvpKfYkZNvRbYtQvanDjugv7zhNFgJwnKKtMNXx3yMwExaRfaDVXZXI2Taj7YDOKwtf4U+WirikJDHS53p0D4bwG65VPKlAPvyrdOF3r8wp5HC3qlAmS2wJXTQLLpI0e9AkTI4UeQ2h7cahHVs7JjPg7BLXXwgsnd4oknJNJ1nv6VmKZ8PBtOI9pPz8AjYnbIe1JkTCK/LiTBjqeASStIhf35K/7Z6ds/DjZ84BYS8GaIYWex9FmR7MTxscNOoEFtqbhNqi6+p/bYF/iB1TGFeVBnzFL1TToNHQ154Y9zu67sw41JfgRwHney2hSvZowd3f0Fez+w4JCZFFCheogilpwf95byMZQcyagZ58hjhXHbpG5HMVE6KIZRyv4210MGvXAgRzL3YlqexVlaUpnzytWzADOvaHycsyg

# Verify current user configured in aws cli
aws sts get-caller-identity

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SSJZFJQPPD:eksdevsession103",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-developer-role/eksdevsession103"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 


# Clean-Up kubeconfig
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Nodes
kubectl get nodes

# Change Directory 
cd 25-EKS-DeveloperAccess-IAM-Users/04-k8sresources-terraform-manifests

# Deploy Terraform Manifests of Sample App to Dev Namespace using hr-dev-eksdeveloper1 user
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# Verify Dev Namespace resources using hr-dev-eksdeveloper1 user
kubectl get deploy -n dev
kubectl get pods -n dev
kubectl get svc -n dev

# Access App
http://CLB-DNS
http://NLB-DNS

# Clean-Up - Apps from Dev Namespace 
cd 25-EKS-DeveloperAccess-IAM-Users/04-k8sresources-terraform-manifests
terraform apply -destroy -auto-approve
rm -rf .terraform*
```


## Step-28: Set AWS CLI to default profile
```t
# To return to the IAM user, remove the environment variables:
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Verify current user configured in aws cli
aws sts get-caller-identity
Observation: It should switch back to current AWS_DEFAULT_PROFILE hr-dev-eksdeveloper1

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S4AEP4ILE2",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksdeveloper1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 

# Set default profile
export AWS_DEFAULT_PROFILE=default

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SSJRDGMFBM",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/kalyandev"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$
```


## Step-29: Login as hr-dev-eksdeveloper1 user AWS Mgmt Console and Switch Roles
- Login to AWS Mgmt Console
  - **Username:** hr-dev-eksdeveloper1
  - **Password:** @EKSUser101
- Go to EKS Servie: https://console.aws.amazon.com/eks/home?region=us-east-1#
```t
# Error
Error loading clusters
User: arn:aws:iam::180789647333:user/hr-dev-eksadmin1 is not authorized to perform: eks:ListClusters on resource: arn:aws:eks:us-east-1:180789647333:cluster/*
```  
- Click on **Switch Role**
  - **Account:** <YOUR_AWS_ACCOUNT_ID> 
  - **Role:** hr-dev-eks-developer-role
  - **Display Name:** eksdeveloper-session201
  - Select Color: any color
- Access EKS Cluster -> hr-dev-eksdemo1
  - Overview Tab
  - Workloads Tab
  - Configuration Tab  
- All should be accessible without any issues.


## Step-30: Cleanup - EKS Cluster
```t
# Set default profile
export AWS_DEFAULT_PROFILE=default

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Change Directory
cd 25-EKS-DeveloperAccess-IAM-Users/01-ekscluster-terraform-manifests


# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-22: Clean-up AWS CLI Profiles
```t
# Clean-up AWS Credentials File
vi /Users/kalyanreddy/.aws/credentials
Remove hr-dev-eksdeveloper1 creds

# Clean-Up AWS Config File
vi /Users/kalyanreddy/.aws/config 
Remove hr-dev-eksdeveloper1 profiles

# List Profiles - AWS CLI
aws configure list-profiles
```

## Step-23: Comment the Policies in c11-01-iam-role-eksdeveloper.tf
- **File:** c11-01-iam-role-eksdeveloper.tf
```t
/*
## ENABLE DURING STEP-24 of the DEMO ## 
# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-developrole-s3fullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.eks_developer_role.name
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-developrole-dynamodbfullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.eks_developer_role.name
}
*/
```

## Step-24: Review Additional Files
- **Folder:** 02-kube-manifests-rb-r
- **Folder:** other-files