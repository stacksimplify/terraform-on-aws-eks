---
title: Create new AWS Basic User to access EKS Cluster Resources
description: Learn how to Create new AWS Basic User to access EKS Cluster Resources
---

## Step-01: Introduction
1. Create AWS IAM User with basic Access (No policies associated related to AWS Admin access)
2. Create IAM Policy with EKS full access and associate that to newly created AWS IAM user
3. Grant the IAM user with Kubernetes `system:masters` permission in EKS Cluster `aws-auth configmap`
4. Verify Access to EKS Cluster using `kubectl` with new IAM basic user
5. Verify access to EKS Cluster Dashboard using AWS Mgmt Console with new IAM basic user
6. Clean-Up users and policies created
7. Finally clean-up cluster


## Step-02: Pre-requisite: Verify EKS Cluster created or not
### Project-01: 01-ekscluster-terraform-manifests
```t
# Change Directroy
cd 20-EKS-Admins-AWS-Basic-User/01-ekscluster-terraform-manifests

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

## Step-03: Create AWS IAM User with Basic Access
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" from "default" profile

# Create IAM User
aws iam create-user --user-name eksadmin2

# Set password for eksadmin1 user
aws iam create-login-profile --user-name eksadmin2 --password @EKSUser101 --no-password-reset-required

# Create Security Credentials for IAM User and make a note of them
aws iam create-access-key --user-name eksadmin2

# Make a note of Access Key ID and Secret Access Key
User: eksadmin2
{
    "AccessKey": {
        "UserName": "eksadmin2",
        "AccessKeyId": "AKIASUF7HC7SXRXBAGM6",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2022-03-12T03:17:16+00:00"
    }
}

```  

## Step-04: EKS Cluster access using kubectl
- We already know from previous demo that `aws-auth` should be configured with user details to work via kubectl. 
- So we will test kubectl access after updating the eks configmap `aws-auth`

## Step-05: Access EKS Cluster resources using AWS Mgmt Console
- Login to AWS Mgmt Console
  - **Username:** eksadmin2
  - **Password:** @EKSUser101
- **Access URL:** https://console.aws.amazon.com/eks/home?region=us-east-1  
- Go to Services -> Elastic Kubernetes Service -> Clusters -> Click on **hr-dev-eksdemo1**
- **Error**
```t
# Error 
Error loading clusters
User: arn:aws:iam::180789647333:user/eksadmin2 is not authorized to perform: eks:ListClusters on resource: arn:aws:eks:us-east-1:180789647333:cluster/*
```

## Step-06: Configure Kubernetes configmap aws-auth with eksadmin2 user
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation:
1. We can update aws-auth configmap using "eksadmin1" user or cluster creator user "kalyandev"

# Get IAM User and make a note of arn
aws iam get-user --user-name eksadmin2

# To edit configmap
kubectl -n kube-system edit configmap aws-auth

## mapUsers TEMPLATE (Add this under "data")
  mapUsers: |
    - userarn: <REPLACE WITH USER ARN>
      username: admin
      groups:
        - system:masters

## mapUsers TEMPLATE - Replaced with IAM User ARN
  mapUsers: |
    - userarn: arn:aws:iam::180789647333:user/eksadmin1
      username: eksadmin1
      groups:
        - system:masters     
    - userarn: arn:aws:iam::180789647333:user/eksadmin2
      username: eksadmin2
      groups:
        - system:masters              

# Verify Nodes if they are ready (only if any errors occured during update)
kubectl get nodes --watch

# Verify aws-auth config map after making changes
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
  mapUsers: |
    - userarn: arn:aws:iam::180789647333:user/eksadmin1
      username: eksadmin1
      groups:
        - system:masters
    - userarn: arn:aws:iam::180789647333:user/eksadmin2
      username: eksadmin2
      groups:
        - system:masters
kind: ConfigMap
metadata:
  creationTimestamp: "2022-03-12T01:19:22Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "16741"
  uid: e082bd27-b580-4e52-933b-63c56f06c99b
```

## Step-07: Configure eksadmin2 user AWS CLI Profile 
```t
# To list all configuration data
aws configure list

# To list all your profile names
aws configure list-profiles

# Configure aws cli eksadmin1 Profile 
aws configure --profile eksadmin2
AWS Access Key ID: AKIASUF7HC7SXRXBAGM6
AWS Secret Access Key: ISxhW0UqsJ8F7navagIs8UqsKfKI22g9lO5SLruJ
Default region: us-east-1
Default output format: json

# To list all your profile names
aws configure list-profiles
```

## Step-08: Configure kubeconfig with eksadmin2 user
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity

# Clean-Up kubeconfig
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for kubectl with AWS CLI Profile eksadmin2
aws eks --region <region-code> update-kubeconfig --name <cluster_name> --profile <AWS-CLI-Profile-NAME>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 --profile eksadmin2
Observation:
1. It should fail

# Verify kubeconfig 
cat $HOME/.kube/config
      env:
      - name: AWS_PROFILE
        value: eksadmin2
Observation: At the end of kubeconfig file we find that AWS_PROFILE it is using is "eksadmin2" profile 

## ERROR MESSAGE
Kalyans-MacBook-Pro:01-ekscluster-terraform-manifests kdaida$ aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 --profile eksadmin2

An error occurred (AccessDeniedException) when calling the DescribeCluster operation: User: arn:aws:iam::180789647333:user/eksadmin2 is not authorized to perform: eks:DescribeCluster on resource: arn:aws:eks:us-east-1:180789647333:cluster/hr-dev-eksdemo1
Kalyans-MacBook-Pro:01-ekscluster-terraform-manifests kdaida$ 
```

## Step-09: Create IAM Policy to access EKS Cluster full access via AWS Mgmt Console
- **IAM Policy Name:** eks-full-access-policy 
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Create IAM Policy
cd 20-EKS-Admins-AWS-Basic-User/iam-files
aws iam create-policy --policy-name eks-full-access-policy --policy-document file://eks-full-access-policy.json

# Attach Policy to eksadmin2 user (Update ACCOUNT-ID and Username)
aws iam attach-user-policy --policy-arn <POLICY-ARN> --user-name <USER-NAME>
aws iam attach-user-policy --policy-arn arn:aws:iam::180789647333:policy/eks-full-access-policy --user-name eksadmin2
```
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "eks:*",
                "ssm:GetParameter"
            ],
            "Resource": "*"
        }
    ]
}         
```

## Step-10: Access EKS Cluster resources using AWS Mgmt Console
- Login to AWS Mgmt Console
  - **Username:** eksadmin2
  - **Password:** @EKSUser101
- Go to Services -> Elastic Kubernetes Service -> Clusters -> Click on **hr-dev-eksdemo1**
- All 3 tabs should be accessible to us without any issues with eksadmin1 user
  - Overview Tab
  - Workloads Tab
  - Configuration Tab

## Step-11: Configure kubeconfig for eksadmin2 user
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Clean-Up kubeconfig
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for kubectl with AWS CLI Profile eksadmin2
aws eks --region <region-code> update-kubeconfig --name <cluster_name> --profile <AWS-CLI-Profile-NAME>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 --profile eksadmin2
Observation:
1. It should pass

# Verify kubeconfig 
cat $HOME/.kube/config
      env:
      - name: AWS_PROFILE
        value: eksadmin2
Observation: At the end of kubeconfig file we find that AWS_PROFILE it is using is "eksadmin2" profile  

# List Kubernetes Nodes
kubectl get nodes
```
## Step-12: Clean-Up Users and IAM Policy
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Delete IAM User
Login to AWS Mgmt Console -> Services -> IAM  -> Users
eksadmin1
eksadmin2

# Delete IAM Policy
Login to AWS Mgmt Console -> Services -> IAM  -> Policies
Delete IAM Policy: eks-full-access-policy
```
## Step-13: Clean-Up EKS Cluster
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile

# Change Directory
cd 19-EKS-Admins-AWS-Admin-User/01-ekscluster-terraform-manifests/

# Destroy EKS Cluster
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-14: Clean-up AWS CLI Profiles
```t
# Clean-up AWS Credentials File
vi /Users/kalyanreddy/.aws/credentials
Remove eksadmin1 and eksadmin2 creds

# Clean-Up AWS Config File
vi /Users/kalyanreddy/.aws/config 
Remove eksadmin1 and eksadmin2 profiles

# List Profiles - AWS CLI
aws configure list-profiles
```


## Additional References
- [Enabling IAM user and role access to your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- [AWS CLI Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)