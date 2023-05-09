---
title: EKS Admins with IAM Roles
description: Learn how to Create EKS Admins with IAM Roles
---

## Step-01: Introduction
1. Create IAM Role with inline policy with EKS Full access.
2. Also Add Trust relationships policy in the same IAM Role
3. Create IAM Group with inline IAM Policy with `sts:AssumeRole`
4. Create IAM Group and associate the IAM Group policy
5. Create IAM User and associate to IAM Group
6. Test EKS Cluster access using credentials generated using `aws sts assume-role` and `kubectl`
7. Test EKS Cluster Dashboard access using `AWS Switch Role` concept via AWS Management Console


## Step-02: Pre-requisite: Create EKS Cluster
- We are going to create the the EKS Cluster as part of this Section

### Project-01: 01-ekscluster-terraform-manifests
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Change Directroy
cd 22-EKS-Admins-with-AWS-IAM-Roles/01-ekscluster-terraform-manifests

# Terraform Initialize
terraform init

# List Terraform Resources (if already EKS Cluster created as part of previous section we can see those resources)
terraform state list

# Else Run below Terraform Commands
terraform validate
terraform plan
terraform apply -auto-approve

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```

## Step-03: Create IAM Role, IAM Trust Policy and IAM Policy
```t
# Verify User (Ensure you are using AWS Admin)
aws sts get-caller-identity

# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# IAM Trust Policy 
POLICY=$(echo -n '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'; echo -n "$ACCOUNT_ID"; echo -n ':root"},"Action":"sts:AssumeRole","Condition":{}}]}')

# Verify both values
echo ACCOUNT_ID=$ACCOUNT_ID
echo POLICY=$POLICY

# Create IAM Role
aws iam create-role \
  --role-name eks-admin-role \
  --description "Kubernetes administrator role (for AWS IAM Authenticator for Kubernetes)." \
  --assume-role-policy-document "$POLICY" \
  --output text \
  --query 'Role.Arn'

# Create IAM Policy - EKS Full access
cd iam-files
aws iam put-role-policy --role-name eks-admin-role --policy-name eks-full-access-policy --policy-document file://eks-full-access-policy.json
```

## Step-04: Create IAM User Group named eksadmins
```t
# Create IAM User Groups
aws iam create-group --group-name eksadmins
```

## Step-05: Add Group Policy to eksadmins Group
- Let’s add a Policy on our group which will allow users from this group to assume our kubernetes admin Role:
```t
# Verify AWS ACCOUNT_ID is set
echo $ACCOUNT_ID

# IAM Group Policy
ADMIN_GROUP_POLICY=$(echo -n '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeOrganizationAccountRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::'; echo -n "$ACCOUNT_ID"; echo -n ':role/eks-admin-role"
    }
  ]
}')

# Verify Policy (if AWS Account Id replaced in policy)
echo $ADMIN_GROUP_POLICY

# Create Policy
aws iam put-group-policy \
--group-name eksadmins \
--policy-name eksadmins-group-policy \
--policy-document "$ADMIN_GROUP_POLICY"
```

## Step-06: Gives Access to our IAM Roles in EKS Cluster
```t
# Verify aws-auth configmap before making changes
kubectl -n kube-system get configmap aws-auth -o yaml

# Edit aws-auth configmap
kubectl -n kube-system edit configmap aws-auth

# ADD THIS in data -> mapRoles section of your aws-auth configmap
# Replace ACCOUNT_ID and EKS-ADMIN-ROLE
    - rolearn: arn:aws:iam::<ACCOUNT_ID>:role/<EKS-ADMIN-ROLE>
      username: eks-admin
      groups:
        - system:masters

# When replaced with Account ID and IAM Role Name
  mapRoles: |
    - rolearn: arn:aws:iam::180789647333:role/hr-dev-eks-nodegroup-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::180789647333:role/eks-admin-role
      username: eks-admin
      groups:
        - system:masters
 
# Verify aws-auth configmap after making changes
kubectl -n kube-system get configmap aws-auth -o yaml
```

### Sample Output
```yaml
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::180789647333:role/hr-dev-eks-nodegroup-role
      username: system:node:{{EC2PrivateDNSName}}
    - rolearn: arn:aws:iam::180789647333:role/eks-admin-role
      username: eks-admin
      groups:
        - system:masters
kind: ConfigMap
metadata:
  creationTimestamp: "2022-03-12T05:33:28Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "1336"
  uid: f8174f23-554a-43e0-b47a-5eba338605ea
```


## Step-07: Create IAM User and Associate to IAM Group
```t   
# Create IAM User
aws iam create-user --user-name eksadmin1

# Associate IAM User to IAM Group  eksadmins
aws iam add-user-to-group --group-name <GROUP> --user-name <USER>
aws iam add-user-to-group --group-name eksadmins --user-name eksadmin1

# Set password for eksadmin1 user
aws iam create-login-profile --user-name eksadmin1 --password @EKSUser101 --no-password-reset-required

# Create Security Credentials for IAM User and make a note of them
aws iam create-access-key --user-name eksadmin1

# Sample Output
{
    "AccessKey": {
        "UserName": "eksadmin1",
        "AccessKeyId": "AKIASUF7HC7SRJ3MIWDF",
        "Status": "Active",
        "SecretAccessKey": "nUQYMdk5FdImSD4/uWPFh1wJMaQf2hHFnTr0BlXi",
        "CreateDate": "2022-03-12T05:37:39+00:00"
    }
}
```

## Step-08: Configure eksadmin1 user AWS CLI Profile and Set it as Default Profile
```t
# To list all configuration data
aws configure list

# To list all your profile names
aws configure list-profiles

# Configure aws cli eksadmin1 Profile 
aws configure --profile eksadmin1
AWS Access Key ID: AKIASUF7HC7SRJ3MIWDF
AWS Secret Access Key: nUQYMdk5FdImSD4/uWPFh1wJMaQf2hHFnTr0BlXi
Default region: us-east-1
Default output format: json

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Set default profile
export AWS_DEFAULT_PROFILE=eksadmin1

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should the user "eksadmin1" from eksadmin1 profile, refer below sample output

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SQWWZGSGY7",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/eksadmin1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 

# Clean-Up kubeconfig
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1
Observation: Should fail
```


## Step-09: Assume IAM Role and Configure kubectl 
```t
# Export AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $ACCOUNT_ID

# Assume IAM Role
aws sts assume-role --role-arn "arn:aws:iam::<REPLACE-YOUR-ACCOUNT-ID>:role/eks-admin-role" --role-session-name eksadminsession01
aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/eks-admin-role" --role-session-name eksadminsession101

# GET Values and replace here
export AWS_ACCESS_KEY_ID=RoleAccessKeyID
export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
export AWS_SESSION_TOKEN=RoleSessionToken

## SAMPLE FOR REFERENCE
export AWS_ACCESS_KEY_ID=ASIASUF7HC7SQXB5EHPV
export AWS_SECRET_ACCESS_KEY=oSIwk+vJW9XoXbPTHt5+6/mNQqMJzLul1QRJ1d2C
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEK7//////////wEaCXVzLWVhc3QtMSJIMEYCIQDPkGKDxwIdGt+D2vBHGYtiu4gJzQor6+saBwbKO6ZQkAIhANRm3TnVVnBwewDnZTAklwt/ghy4SvA204YaTpEnv1yVKp8CCCcQAxoMMTgwNzg5NjQ3MzMzIgw9un24WGzvuG2wQ6cq/AFspVDHeXeAHbUHyAc2eh9WcjSG0NQ9cE/6Mjk/9PseI96xhOxp8q/fGoqELyrxy5kBSI0qEaPPIgWOGZ/v410P/GrneVrJ3kY7w18wUV5te1FzfE0VuALwILiXwnyAzv21w7PmqAufpGBGf/nU5oqQlsRGwNqX9nLvkmWutY9zMg2dxOtA9kRUqbDpi3zzSXypH5gkF1ZhCqxxMdjvOu4XkzjrU2vprwt2Q4joXHCOYhqEUJ0CpfKga58QnLJL0EfYWBj4UIU3/LVCxN6HBfqH84lYwEOvK43FMvNQ2bhSeueGCq624Zj/insUkP0uhqbDrxeJ7lU0cmX2JrcwtOewkQY6nAHEpez7tN6MXY5/QQWokVe1hgqB5AzpoBGRoOa2hjvH5hcvmFfJ/S360hPa60JXR+mewZG6p8O7LVwtOHTb9/h6+10iud8zdKM45+rYJAjb+geiGanY1WIvfh8DOFmpdEQQCq7QrUlLvJJ0grtoSv9u1sczPUlyWCJDkj20y8Pb4kupDSPKm96DU/3Do5vMktr5T7l/bJQWMMh7z2M=


# Verify current user configured in aws cli
aws sts get-caller-identity

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AROASUF7HC7S7PCTLZCTE:eksadminsession101",
    "Account": "180789647333",
    "Arn": "arn:aws:sts::180789647333:assumed-role/eks-admin-role/eksadminsession101"
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

# To return to the IAM user, remove the environment variables:
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Verify current user configured in aws cli
aws sts get-caller-identity
Observation: It should switch back to current AWS_DEFAULT_PROFILE eksadmin1

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SQWWZGSGY7",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/eksadmin1"
}
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$
```

## Step-10: Login as eksadmin1 user AWS Mgmt Console and Switch Roles
- Login to AWS Mgmt Console
  - Username: eksadmin1
  - Password: @EKSUser101
- Go to EKS Servie: https://console.aws.amazon.com/eks/home?region=us-east-1#
```t
# Error
Error loading clusters
User: arn:aws:iam::180789647333:user/eksadmin1 is not authorized to perform: eks:ListClusters on resource: arn:aws:eks:us-east-1:180789647333:cluster/*
```  
- Click on **Switch Role**
  - **Account:** <YOUR_AWS_ACCOUNT_ID> 
  - **Role:** eks-admin-role
  - **Display Name:** eksadmin-session101
  - **Select Color:** any color
- Access EKS Cluster -> hr-dev-eksdemo1
  - Overview Tab
  - Workloads Tab
  - Configuration Tab  
- All should be accessible without any issues.

## Step-11: Clean-Up IAM Roles, users and Groups
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should the user "eksadmin1" from eksadmin1 profile

# Set default profile
export AWS_DEFAULT_PROFILE=default

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Delete IAM Role Policy and IAM Role 
aws iam delete-role-policy --role-name eks-admin-role --policy-name eks-full-access-policy
aws iam delete-role --role-name eks-admin-role

# Remove IAM User from IAM Group
aws iam remove-user-from-group --user-name eksadmin1 --group-name eksadmins

# Delete IAM User Login profile
aws iam delete-login-profile --user-name eksadmin1

# Delete IAM Access Keys
aws iam list-access-keys --user-name eksadmin1
aws iam delete-access-key --access-key-id <REPLACE AccessKeyId> --user-name eksadmin1
aws iam delete-access-key --access-key-id AKIASUF7HC7SRJ3MIWDF --user-name eksadmin1

# Delete IAM user
aws iam delete-user --user-name eksadmin1

# Delete IAM Group Policy
aws iam delete-group-policy --group-name eksadmins --policy-name eksadmins-group-policy

# Delete IAM Group
aws iam delete-group --group-name eksadmins
```

## Step-12: Cleanup - EKS Cluster
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```
 
## Step-14: Clean-up AWS CLI Profiles
```t
# Clean-up AWS Credentials File
vi /Users/kalyanreddy/.aws/credentials
Remove eksadmin1 creds

# Clean-Up AWS Config File
vi /Users/kalyanreddy/.aws/config 
Remove eksadmin1 profiles

# List Profiles - AWS CLI
aws configure list-profiles
```
