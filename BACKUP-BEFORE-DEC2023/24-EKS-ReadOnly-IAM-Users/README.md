---
title: Kubernetes Role and Role Binding
description: Kubernetes Role and Role Binding in combination with AWS IAM Role, Group and User on EKS Cluster
---

## Step-01: Introduction
### All the below steps we implement using Terraform
1. Create IAM Role with inline policy with EKS ReadOnly access.
2. Also Add Trust relationships policy in the same IAM Role
3. Create IAM Group with inline IAM Policy with `sts:AssumeRole`
4. Create IAM Group and associate the IAM Group policy
5. Create IAM User and associate to IAM Group
6. Create Kubernetes `ClusterRole` and `ClusterRoleBinding`
7. Update `aws-auth ConfigMap` with EKS ReadOnly Role in `mapRoles` section
8. Create EKS Cluster
9. Test EKS Cluster access using credentials generated using `aws sts assume-role` and `kubectl`
10. Test EKS Cluster Dashboard access using `AWS Switch Role` concept via AWS Management Console

## Step-02: Create IAM Role with IAM STS Assume Role Trust Policy and IAM EKS Read-Only Access Policy
- **File:** c10-01-iam-role-eksreadonly.tf
```t
# Resource: AWS IAM Role - EKS Read-Only User
resource "aws_iam_role" "eks_readonly_role" {
  name = "${local.name}-eks-readonly-role"

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
    name = "eks-readonly-access-policy"

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
    tag-key = "${local.name}-eks-readonly-role"
  }
}

```

## Step-03: Create Resource: IAM Group 
- **File:** c10-02-iam-group-and-user-eksreadonly.tf
```t
# Resource: AWS IAM Group 
resource "aws_iam_group" "eksreadonly_iam_group" {
  name = "${local.name}-eksreadonly"
  path = "/"
}
```
## Step-04: Create Resource: IAM Group Policy 
- **File:** c10-02-iam-group-and-user-eksreadonly.tf
```t

# Resource: AWS IAM Group Policy
resource "aws_iam_group_policy" "eksreadonly_iam_group_assumerole_policy" {
  name  = "${local.name}-eksreadonly-group-policy"
  group = aws_iam_group.eksreadonly_iam_group.name

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
        Resource = "${aws_iam_role.eks_readonly_role.arn}"
      },
    ]
  })
}
```
## Step-05: Create Resource: IAM User
- **File:** c10-02-iam-group-and-user-eksreadonly.tf
```t
# Resource: AWS IAM User 
resource "aws_iam_user" "eksreadonly_user" {
  name = "${local.name}-eksreadonly1"
  path = "/"
  force_destroy = true
  tags = local.common_tags
}
```
## Step-06: Create Resource: IAM Group Membership
- **File:** c10-02-iam-group-and-user-eksreadonly.tf
```t
# Resource: AWS IAM Group Membership
resource "aws_iam_group_membership" "eksreadonly" {
  name = "${local.name}-eksreadonly-group-membership"
  users = [
    aws_iam_user.eksreadonly_user.name
  ]
  group = aws_iam_group.eksreadonly_iam_group.name
}
```

## Step-07: Create Kubernetes ClusterRole Resource
- **File:** c10-03-k8s-clusterrole-clusterrolebinding.tf
```t
# Resource: Cluster Role
resource "kubernetes_cluster_role_v1" "eksreadonly_clusterrole" {
  metadata {
    name = "${local.name}-eksreadonly-clusterrole"
  }

  rule {
    api_groups = [""] # These come under core APIs
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
- **File:** c10-03-k8s-clusterrole-clusterrolebinding.tf
```t

# Resource: Cluster Role Binding
resource "kubernetes_cluster_role_binding_v1" "eksreadonly_clusterrolebinding" {
  metadata {
    name = "${local.name}-eksreadonly-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksreadonly_clusterrole.metadata.0.name 
  }
  subject {
    kind      = "Group"
    name      = "eks-readonly-group"
    api_group = "rbac.authorization.k8s.io"
  }
}
```
## Step-09: Update Locals Block with IAM Role
- **File:** c7-02-kubernetes-configmap.tf
```t
# Get AWS Account ID
data "aws_caller_identity" "current" {}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

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
## Step-10: Update Kubernetes aws-auth ConfigMap Resource
- **File:** c7-02-kubernetes-configmap.tf
- Add Resource `kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding` in depends_on Meta-Argument 
```t
# Resource: Kubernetes Config Map
resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [
    aws_eks_cluster.eks_cluster,
    kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding
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
## Step-11: Execute Terraform Commands
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Change Directory
cd 24-EKS-ReadOnly-IAM-Users/01-ekscluster-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-12: Verify aws-auth ConfigMap after EKS Cluster Creation
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

## Step-13: Create IAM User Login Profile and User Security Credentials
```t
# Set password for hr-dev-eksreadonly1 user
aws iam create-login-profile --user-name hr-dev-eksreadonly1 --password @EKSUser101 --no-password-reset-required

# Create Security Credentials for IAM User and make a note of them
aws iam create-access-key --user-name hr-dev-eksreadonly1

# Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws iam create-access-key --user-name hr-dev-eksreadonly1
{
    "AccessKey": {
        "UserName": "hr-dev-eksreadonly1",
        "AccessKeyId": "AKIASUF7HC7SXRQN6CFR",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2022-04-24T05:40:49+00:00"
    }
}

Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```


## Step-14: Configure hr-dev-eksreadonly1 user AWS CLI Profile and Set it as Default Profile
```t
# To list all configuration data
aws configure list

# To list all your profile names
aws configure list-profiles

# Configure aws cli eksadmin1 Profile 
aws configure --profile hr-dev-eksreadonly1
AWS Access Key ID: AKIASUF7HC7SXRQN6CFR
AWS Secret Access Key: z3ZrF/cbJe2Oe8i7ud+184ggHOCEJ5m5IFzYqB55
Default region: us-east-1
Default output format: json

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Set default profile
export AWS_DEFAULT_PROFILE=hr-dev-eksreadonly1

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "hr-dev-eksreadonly1" from hr-dev-eksreadonly1 profile, refer below sample output

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S4AEP4ILE2",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksreadonly1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```
## Step-15: Assume IAM Role and Configure kubectl and Access Kubernetes Objects which user hr-dev-eksreadonly1 has access
```t
# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# Assume IAM Role
aws sts assume-role --role-arn "arn:aws:iam::<REPLACE-YOUR-ACCOUNT-ID>:role/eks-admin-role" --role-session-name eksadminsession201
aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/hr-dev-eks-readonly-role" --role-session-name eksadminsession901

# GET Values and replace here
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
export AWS_SESSION_TOKEN=RoleSessionToken

## SAMPLE FOR REFERENCE
export AWS_ACCESS_KEY_ID=ASIASUF7HC7ST5IDV2AW
export AWS_SECRET_ACCESS_KEY=3EbIB/OHTXiVINcscDvNCEFK8ztluZwzO9MVRkGx
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjELb//////////wEaCXVzLWVhc3QtMSJIMEYCIQC2OR2qL03yKw7DjdBWmvf7ohjsNUb4Vrq74PvO+JzQigIhAOw5Axq4UNy1KYp23Wh8HpwfBKwYW8DBPyZwA/G0DA1iKp8CCG8QAxoMMTgwNzg5NjQ3MzMzIgxDW1nBSVLDibShcl0q/AENa9vxBrtzxDdqlssdXNHB1x1sgHie0jVRsE41t9dF1KBbaGgRawtVSxru4HkcGkK5FtF+RC0D2dts0vR8BNLIXilla0nOk15tOFOgn9PMzbY7iA7gIZT9Yo/T3OaF3UkHkZzJGV1uFE7badnNfHNn3IEYwFExilkI7fD60idz9Q/OkTl/jQ7FCo8X3NxjOvr82J53sDmzF0U4G3EZ8E47EHc5+xCS91PGkQ8Qt1aI0Vl76DYgmLeFgDBruK9Bs1BAqDRTdLyvpDlhTj1Z7Q3XMNzEScPQyrS9aSlMZsBt01RZ//JTRMIBouahiKBKPDM17pFk+ThVamQpdfIwnMeTkwY6nAG1dORHi6cgaRCZHa+gfTEm9D8wVii/rTtiZLrUzRa7vj++XuU9r2YMNFnOBS6UcbqHJzQ+YFZaWdQPhuZZNYGTEefuebVG58+mtdedc2BRp23sxHXAMaIiKk2oIaVUpZwB78i5QZhUCAg9SIOSoRhiFEX63kDYlf+ICTnz0+4L6xMENk0/mmw48TKOu5JrgQwz6C3vlwjuQ1tMh6M=

# Verify current user configured in aws cli
aws sts get-caller-identity

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SRFLFPNG7F:eksadminsession901",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-readonly-role/eksadminsession901"
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

## Step-16: Assume IAM Role and Configure kubectl and Access Kubernetes Objects which user hr-dev-eksreadonly1 don't have access
```t
# Verify aws-auth configmap
kubectl -n kube-system get configmap aws-auth -o yaml
Observation: Should fail because we didn't access to ConfigMap resources in API Group "" (Core APIs)

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ kubectl -n kube-system get configmap aws-auth -o yaml
Error from server (Forbidden): configmaps "aws-auth" is forbidden: User "eks-readonly" cannot get resource "configmaps" in API group "" in the namespace "kube-system"
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 


# Verify Service Accounts
kubectl get sa
kubectl get sa -n kube-system
Observation: Should fail because we didn't access to ServiceAccount resources in API Group "" (Core APIs)

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ kubectl get sa -n kube-system
Error from server (Forbidden): serviceaccounts is forbidden: User "eks-readonly" cannot list resource "serviceaccounts" in API group "" in the namespace "kube-system"
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 

# Verify get all from kube-system namespace
kubectl get all -n kube-system

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ kubectl get all -n kube-system
NAME                          READY   STATUS    RESTARTS   AGE
pod/aws-node-mt8sl            1/1     Running   0          34m
pod/coredns-7f5998f4c-cblh2   1/1     Running   0          39m
pod/coredns-7f5998f4c-k9qzd   1/1     Running   0          39m
pod/kube-proxy-66jpt          1/1     Running   0          34m

NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/aws-node     1         1         1       1            1           <none>          39m
daemonset.apps/kube-proxy   1         1         1       1            1           <none>          39m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/coredns   2/2     2            2           39m

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/coredns-7f5998f4c   2         2         2       39m
Error from server (Forbidden): replicationcontrollers is forbidden: User "eks-readonly" cannot list resource "replicationcontrollers" in API group "" in the namespace "kube-system"
Error from server (Forbidden): services is forbidden: User "eks-readonly" cannot list resource "services" in API group "" in the namespace "kube-system"
Error from server (Forbidden): horizontalpodautoscalers.autoscaling is forbidden: User "eks-readonly" cannot list resource "horizontalpodautoscalers" in API group "autoscaling" in the namespace "kube-system"
Error from server (Forbidden): cronjobs.batch is forbidden: User "eks-readonly" cannot list resource "cronjobs" in API group "batch" in the namespace "kube-system"
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```

## Step-17: Set AWS CLI to default profile
```t
# To return to the IAM user, remove the environment variables:
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Verify current user configured in aws cli
aws sts get-caller-identity
Observation: It should switch back to current AWS_DEFAULT_PROFILE hr-dev-eksreadonly1

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S4AEP4ILE2",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksreadonly1"
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

## Step-18: Update ClusterRole with additional resources for core apigroup ""
- **File Name:** c10-03-k8s-clusterrole-clusterrolebinding.tf
- Add **configmaps** and **serviceaccounts**
```t
# Resource: Cluster Role
resource "kubernetes_cluster_role_v1" "eksreadonly_clusterrole" {
  metadata {
    name = "eksreadonly-clusterrole"
  }

  rule {
    api_groups = [""] # These come under core APIs
    #resources  = ["nodes", "namespaces", "pods", "events", "services"]
    resources  = ["nodes", "namespaces", "pods", "events", "services", "configmaps", "serviceaccounts"] #Uncomment for additional Testing
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

## Step-19: Test newly added Resources with hr-dev-eksreadonly1 user
```t
# Set default profile
export AWS_DEFAULT_PROFILE=hr-dev-eksreadonly1

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "hr-dev-eksreadonly1" from hr-dev-eksreadonly1 profile, refer below sample output

# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# Assume IAM Role
aws sts assume-role --role-arn "arn:aws:iam::<REPLACE-YOUR-ACCOUNT-ID>:role/eks-admin-role" --role-session-name eksadminsession201
aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/hr-dev-eks-readonly-role" --role-session-name eksadminsession501

# GET Values and replace here
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
export AWS_SESSION_TOKEN=RoleSessionToken

# Sample Output
export AWS_ACCESS_KEY_ID=ASIASUF7HC7S6O7OZ6V3
export AWS_SECRET_ACCESS_KEY=IKjUu/ZOw2LXfUQUYmEWZAz7gywvhSsOs0uZjWwq
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjELf//////////wEaCXVzLWVhc3QtMSJHMEUCIDY08vruqgWzUs0EQB0nNqDGUhnGd6BQgdDspdPPIj0MAiEAyxFRJZQ1XbNTatfnKdZKGKaFOPjtrjog1FdDdWQVugQqnwIIcBADGgwxODA3ODk2NDczMzMiDFXUsF9fS+RYVzCsKir8ARygXigzKa13zh9K6EIDrTIo9zRsJ7JPEnt5Gh1YfHtNOyOEvWWhmqFfzZhYxiL9tbZ5d7ZYCDxbjXefN6SKnkEIScmoURAVKOjSd+Ma/Mf+dyyiiZPZYpPkNBQL9aDuDcHL+wRJ07xOFvvkdJnK8hsxW8r0C92I5OJ1pQO3T351MfiwtunQW7YCPpAbmyfDPbXC6Vygtcx3OkOPD/g/1/4fBX4yMYyOgHEvPt4Xtb75hisrU8yWcgv2IKgr3veNjvab8wwQ3zRdXqte0+2r9m8qPj3URqWYVSkSQELOmsNMa5KmPtIeTsOrAOIO7aQ+oWdZ9Jy7oxXfFJprSjCa3JOTBjqdAZU9Lbz/laKQ7dgO5hr2jsMiDFb6ZvwOwFeYkhS30flwQpwniDJdda4lKp/FJVX7bN7YqMGeBwzr14ijy7TQZHXmhnnuGBdVc2ep7jB3hbE5YV0V/+2Ga8lauX0sYpU1KF9LwFf7Ds74Sh0duP15sLoyMLDo7LhSC2xlW5j7NXI4SsU9rOD4RHgsPxaJ/EAHqeb3ls5azE7mPJm6HlI=


# Verify current user configured in aws cli
aws sts get-caller-identity

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7SRFLFPNG7F:eksadminsession501",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/hr-dev-eks-readonly-role/eksadminsession501"
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

# Verify Service Accounts
kubectl get sa
kubectl get sa -n kube-system

# Verify ConfigMaps
kubectl get cm
kubectl get cm -n kube-system

# To return to the IAM user, remove the environment variables:
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Verify current user configured in aws cli
aws sts get-caller-identity
Observation: It should switch back to current AWS_DEFAULT_PROFILE hr-dev-eksreadonly1

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7S4AEP4ILE2",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/hr-dev-eksreadonly1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```

## Step-20: Login as hr-dev-eksreadonly1 user AWS Mgmt Console and Switch Roles
- Login to AWS Mgmt Console
  - **Username:** hr-dev-eksreadonly1
  - **Password:** @EKSUser101
- Go to EKS Servie: https://console.aws.amazon.com/eks/home?region=us-east-1#
```t
# Error
Error loading clusters
User: arn:aws:iam::180789647333:user/hr-dev-eksadmin1 is not authorized to perform: eks:ListClusters on resource: arn:aws:eks:us-east-1:180789647333:cluster/*
```  
- Click on **Switch Role**
  - **Account:** <YOUR_AWS_ACCOUNT_ID> 
  - **Role:** hr-dev-eks-readonly-role
  - **Display Name:** eksreadonly-session201
  - Select Color: any color
- Access EKS Cluster -> hr-dev-eksdemo1
  - Overview Tab
  - Workloads Tab
  - Configuration Tab  
- All should be accessible without any issues.


## Step-21: Cleanup - EKS Cluster
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

## Step-22: Clean-up AWS CLI Profiles
```t
# Clean-up AWS Credentials File
vi /Users/kalyanreddy/.aws/credentials
Remove hr-dev-eksreadonly1 creds

# Clean-Up AWS Config File
vi /Users/kalyanreddy/.aws/config 
Remove hr-dev-eksreadonly1 profiles

# List Profiles - AWS CLI
aws configure list-profiles
```