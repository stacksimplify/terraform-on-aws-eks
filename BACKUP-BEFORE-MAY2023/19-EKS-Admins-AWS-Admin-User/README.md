---
title: Create new AWS Admin User to access EKS Cluster Resources
description: Learn how to Create new AWS Admin User to access EKS Cluster Resources
---

## Step-01: Introduction
1. Create AWS IAM User with Administrator Access
2. Grant the IAM user with Kubernetes `system:masters` permission in EKS Cluster `aws-auth configmap`
3. Verify Access to EKS Cluster using `kubectl` with new AWS IAM admin user
4. Verify access to EKS Cluster Dashboard using AWS Mgmt Console with new AWS IAM admin user

## Step-02: Verify with which user we are creating EKS Cluster
- The user with which we create the EKS Cluster is called **Cluster_Creator_User**.
- This user information is not stored in AWS EKS Cluster aws-auth configmap but we should be very careful about remembering this user info.
- This user can be called as `Master EKS Cluster user` from AWS IAM  and we should remember this user.
- If we face any issues with `k8s aws-auth configmap` and if we lost access to EKS Cluster we need the `cluster_creator` user to restore the stuff. 
```t
# Get current user configured in AWS CLI
aws sts get-caller-identity

# Sample Output
Kalyans-MacBook-Pro:01-ekscluster-terraform-manifests kdaida$ aws sts get-caller-identity
{
    "UserId": "AIDASUF7HC7SSJRDGMFBM",
    "Account": "180789647333",
    "Arn": "arn:aws:iam::180789647333:user/kalyandev"
}

# Make a note of  EKS Cluster Creator user
EKS_Cluster_Create_User: kalyandev (in my environment this is the user)
```

## Step-03: Pre-requisite: Create EKS Cluster
### Project-01: 01-ekscluster-terraform-manifests
```t
# Change Directroy
cd 19-EKS-Admins-AWS-Admin-User/01-ekscluster-terraform-manifests

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

## Step-03: Create AWS IAM User with Admin Access
```t
# Create IAM User
aws iam create-user --user-name eksadmin1

# Attach AdministratorAccess Policy to User
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name eksadmin1

# Set password for eksadmin1 user
aws iam create-login-profile --user-name eksadmin1 --password @EKSUser101 --no-password-reset-required

# Create Security Credentials for IAM User and make a note of them
aws iam create-access-key --user-name eksadmin1

# Make a note of Access Key ID and Secret Access Key
User: eksadmin1
{
    "AccessKey": {
        "UserName": "eksadmin1",
        "AccessKeyId": "AKIASUF7HC7SYK3RO727",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2022-03-20T03:19:02+00:00"
    }
}
```  

## Step-04: Create eksadmin1 user AWS CLI Profile 
```t
# To list all configuration data
aws configure list

# To list all your profile names
aws configure list-profiles

# Configure aws cli eksadmin1 Profile 
aws configure --profile eksadmin1
AWS Access Key ID: AKIASUF7HC7SYK3RO727
AWS Secret Access Key: WQEf+lTcucoaKZt4EDnZmXm5VzqLkFLVWQaJxHiH
Default region: us-east-1
Default output format: json

# Get current user configured in AWS CLI
aws sts get-caller-identity
Observation: Should see the user "kalyandev" (EKS_Cluster_Create_User) from default profile
```

## Step-05: Configure kubeconfig and access EKS resources using kubectl
```t
# Clean-Up kubeconfig
cat $HOME/.kube/config
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for eksadmin1 AWS CLI profile
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 --profile eksadmin1

# Verify kubeconfig file
cat $HOME/.kube/config
      env:
      - name: AWS_PROFILE
        value: eksadmin1
Observation: At the end of kubeconfig file we find that AWS_PROFILE it is using is "eksadmin1" profile   

# Verify Kubernetes Nodes
kubectl get nodes
Observation: 
1. We should fail in accessing the EKS Cluster resources using kubectl

## Sample Output
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ kubectl get nodes
error: You must be logged in to the server (Unauthorized)
Kalyans-Mac-mini:01-ekscluster-terraform-manifests kalyanreddy$ 
```

## Step-06: Access EKS Cluster resources using AWS Mgmt Console
- Login to AWS Mgmt Console
  - **Username:** eksadmin1
  - **Password:** @EKSUser101
- Go to Services -> Elastic Kubernetes Service -> Clusters -> Click on **hr-dev-eksdemo1**
- **Error / Warning**
```t
# Error / Warning
Your current user or role does not have access to Kubernetes objects on this EKS cluster
This may be due to the current user or role not having Kubernetes RBAC permissions to describe cluster resources or not having an entry in the cluster’s auth config map.
```

## Step-07: Review Kubernetes configmap aws-auth
```t
# Verify aws-auth config map before making changes
kubectl -n kube-system get configmap aws-auth -o yaml
Observation: Currently, eksadmin1 is configured as AWS CLI default profile, switch back to default profile. 

# Configure kubeconfig for default AWS CLI profile (Switch back to EKS_Cluster_Create_User to perform these steps)
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 
[or]
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 --profile default

# Verify kubeconfig file
cat $HOME/.kube/config
      env:
      - name: AWS_PROFILE
        value: default
Observation: At the end of kubeconfig file we find that AWS_PROFILE it is using is "default" profile        

# Verify aws-auth config map before making changes
kubectl -n kube-system get configmap aws-auth -o yaml
```
- Review `aws-auth ConfigMap` 
```yaml
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::180789647333:role/hr-dev-eks-nodegroup-role
      username: system:node:{{EC2PrivateDNSName}}
kind: ConfigMap
metadata:
  creationTimestamp: "2022-03-11T00:18:40Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "827"
  uid: 00614a82-89d1-4b11-a7e7-e02cb1ad2d02
```

## Step-08: Configure Kubernetes configmap aws-auth with eksadmin1 user
```t
# Get IAM User and make a note of arn
aws iam get-user --user-name eksadmin1

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
kind: ConfigMap
metadata:
  creationTimestamp: "2022-03-11T00:18:40Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "9571"
  uid: 00614a82-89d1-4b11-a7e7-e02cb1ad2d02
```

## Step-09: Configure kubeconfig with eksadmin1 user
```t
# Clean-Up kubeconfig
>$HOME/.kube/config
cat $HOME/.kube/config

# Configure kubeconfig for eksadmin1 AWS CLI profile
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1 --profile eksadmin1

# Verify kubeconfig file
cat $HOME/.kube/config
      env:
      - name: AWS_PROFILE
        value: eksadmin1
Observation: At the end of kubeconfig file we find that AWS_PROFILE it is using is "eksadmin1" profile

# Verify Kubernetes Nodes
kubectl get nodes
Observation: 
1. We should see access to EKS Cluster via kubectl is success
```
## Step-10: Access EKS Cluster resources using AWS Mgmt Console
- Login to AWS Mgmt Console
  - **Username:** eksadmin1
  - **Password:** @EKSUser101
- Go to Services -> Elastic Kubernetes Service -> Clusters -> Click on **hr-dev-eksdemo1**
- All 3 tabs should be accessible to us without any issues with eksadmin1 user
  - Overview Tab
  - Workloads Tab
  - Configuration Tab



## Additional References 
- [Enabling IAM user and role access to your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- [AWS CLI Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
