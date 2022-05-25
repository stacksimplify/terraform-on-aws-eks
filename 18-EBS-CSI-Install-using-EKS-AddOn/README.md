---
title: Use EKS AddOns to Install EBS CSI Driver
description: Learn to use EKS AddOns to Install EBS CSI Driver
---
## Step-01: Introduction
- Install EBS CSI Driver using EKS AddOn
- [Limitations - EKS Addon EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html

## Step-02: Verify EKS Cluster
```t
# Change Directory 
cd 18-EBS-CSI-Install-using-EKS-AddOn/01-ekscluster-terraform-manifests

# If EKS Cluster not created, run the commands 
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# If EKS Cluster already created as part of previous demos and we are leveraging the same then run below commands to cross check if we are good in Section-16 to move to next step
terraform state list

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# List EKS Worker Nodes
kubectl get nodes -o wide
```

## Step-03: Pre-requisite-1: Create folder in S3 Bucket (Optional)
- This step is optional, Terraform can create this folder `dev/ebs-addon` during `terraform apply` but to maintain consistency we create it. 
- Go to Services -> S3 -> 
- **Bucket name:** terraform-on-aws-eks
- **Create Folder**
  - **Folder Name:** dev/ebs-addon/terraform.tfstate
  - Click on **Create Folder**  

## Step-04: Pre-requisite-2: Create DynamoDB Table
- Create Dynamo DB Table for EBS AddOn
  - **Table Name:** dev-ebs-addon
  - **Partition key (Primary Key):** LockID (Type as String)
  - **Table settings:** Use default settings (checked)
  - Click on **Create**

## Step-05: c1-versions.tf
- **Folder:** `18-EBS-CSI-Install-using-EKS-AddOn/02-ebs-addon-terraform-manifests`
```t
# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.4"
     }
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-on-aws-eks"
    key    = "dev/ebs-addon/terraform.tfstate"
    region = "us-east-1" 

    # For State Locking
    dynamodb_table = "dev-ebs-addon"    
  }     
}

# Terraform Provider Block
provider "aws" {
  region = var.aws_region
}
```
## Step-06: c4-03-ebs-csi-addon-install.tf
- **Folder:** `18-EBS-CSI-Install-using-EKS-AddOn/02-ebs-addon-terraform-manifests`
```t
# Resource: EBS CSI Driver AddOn
# Install EBS CSI Driver using EKS Add-Ons
resource "aws_eks_addon" "ebs_eks_addon" {
  depends_on = [ aws_iam_role_policy_attachment.ebs_csi_iam_role_policy_attach]
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_id
  addon_name   = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_iam_role.arn
}
```
## Step-07: c4-04-ebs-csi-outputs.tf
- **Folder:** `18-EBS-CSI-Install-using-EKS-AddOn/02-ebs-addon-terraform-manifests`
```t
# EKS AddOn - EBS CSI Driver Outputs 
output "ebs_eks_addon_arn" {
  description = "EKS AddOn - EBS CSI Driver ARN"
  value = aws_eks_addon.ebs_eks_addon.arn
}
output "ebs_eks_addon_id" {
    description = "EKS AddOn - EBS CSI Driver ID"
  value = aws_eks_addon.ebs_eks_addon.id
}
```

## Step-08: Create EBS CSI Driver EKS AddOn: Execute TF Commands
```t
# EKS List AddOns for a EKS Cluster
aws eks list-addons --cluster-name hr-dev-eksdemo1
Observation:
1. Before installing the addon we will check if any addons installed

# Change Directory
cd 18-EBS-CSI-Install-using-EKS-AddOn/02-ebs-addon-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-09: Verify EBS CSI Driver installed via EKS Addon
```t
# EKS List AddOns for a EKS Cluster
aws eks list-addons --cluster-name hr-dev-eksdemo1

## Sample Output
{
    "addons": [
        "aws-ebs-csi-driver"
    ]
}

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# List EBS Pods from kube-system namespace
kubectl -n kube-system get pods 

# List EBS Deployment from kube-system namespace
kubectl -n kube-system get deploy 

# List EBS Daemonset from kube-system namespace
kubectl -n kube-system get ds
```

## Step-10: Verify EBS CSI Kubernetes Service Accounts
```t
# List EBS CSI  Kubernetes Service Accounts
kubectl -n kube-system get sa 
Observation:
1. We should find two service accounts related to EBS CSI
  - ebs-csi-controller-sa
  - ebs-csi-node-sa

# Describe EBS CSI Controller Service Account
kubectl -n kube-system describe sa ebs-csi-controller-sa
Observation:
1. Verify the "Annotations" field and you should find our IAM Role created for EBS CSI is associated with EKS Cluster EBS Service Account.
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::180789647333:role/hr-dev-ebs-csi-iam-role
2. Also review the labels
Labels:              app.kubernetes.io/managed-by=EKS
                     app.kubernetes.io/name=aws-ebs-csi-driver
                     app.kubernetes.io/version=1.4.0

# Describe EBS CSI Node Service Account
kubectl -n kube-system describe sa ebs-csi-node-sa
Observation: 
1. Observe the labels
Labels:              app.kubernetes.io/managed-by=EKS
                     app.kubernetes.io/name=aws-ebs-csi-driver
                     app.kubernetes.io/version=1.4.0
```


## Step-11: Deploy EBS Sample App: Execute Terraform Commands
```t
# Change Directory 
cd 18-EBS-CSI-Install-using-EKS-AddOn/03-terraform-manifests-UMS-WebApp

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-12: Verify Kubernetes Resources created
```t
# Verify Storage Class
kubectl get storageclass
kubectl get sc
Observation:
1. You should find two EBS Storage Classes
  - One created by default with in-tree EBS provisioner named "gp2". Future it might get deprecated
  - Recommended to use EBS CSI Provisioner for creating EBS volumes for EKS Workloads
  - That said, we should the one we created with name as "ebs-sc"

# Verify PVC and PV
kubectl get pvc
kubectl get pv
Observation:
1. Status should be in BOUND state

# Verify Deployments
kubectl get deploy
Observation:
1. We should see both deployments in default namespace
- mysql
- usermgmt-webapp

# Verify Pods
kubectl get pods
Observation:
1. You should see both pods running

# Describe both pods and review events
kubectl describe pod <POD-NAME>
kubectl describe pod mysql-6fdd448876-hdhnm
kubectl describe pod usermgmt-webapp-cfd4c7-fnf9s

# Review UserMgmt Pod Logs
kubectl logs -f usermgmt-webapp-cfd4c7-fnf9s
Observation:
1. Review the logs and ensure it is successfully connected to MySQL POD

# Verify Services
kubectl get svc
```

## Step-13: Connect to MySQL Database Pod
```t
# Connect to MySQL Database 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -pdbpassword11

# Verify usermgmt schema got created which we provided in ConfigMap
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;


Observation:
1. If UserMgmt WebApp container successfully started, it will connect to Database and create the default user named admin101
Username: admin101
Password: password101
```
## Step-14: Access Sample Application
```t
# Verify Services
kubectl get svc

# Access using browser
http://<CLB-DNS-URL>
http://<NLB-DNS-URL>
Username: admin101
Password: password101

# Create Users and Verify using UserMgmt WebApp in browser
admin102/password102
admin103/password103

# Verify the same in MySQL DB
## Connect to MySQL Database 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -pdbpassword11

## Verify usermgmt schema got created which we provided in ConfigMap
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
```

## Step-15: Node Port Service Port - Update Node Security Group
- **Important Note:** This is not a recommended option to update the Node Security group to open ports to internet, but just for learning and testing we are doing this. 
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Add an additional Inbound Rule
   - **Type:** Custom TCP
   - **Protocol:** TCP
   - **Port range:** 31280
   - **Source:** Anywhere (0.0.0.0/0)
   - **Description:** NodePort Rule
- Click on **Save rules**


## Step-16: Access Sample using NodePort Service 
```t
# List Nodes
kubectl get nodes -o wide
Observation: Make a note of the Node External IP

# List Services
kubectl get svc
Observation: Make a note of the NodePort service port "myapp1-nodeport-service" which looks as "80:31280/TCP"

# Access the Sample Application in Browser
http://<EXTERNAL-IP-OF-NODE>:<NODE-PORT>
http://54.165.248.51:31280
Username: admin101
Password: password101
```

## Step-17: Remove Inbound Rule added  
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Remove the NodePort Rule which we added.

## Step-18: Clean-Up - UserMgmt WebApp Kubernetes Resources
```t
# Change Directory
cd 18-EBS-CSI-Install-using-EKS-AddOn/03-terraform-manifests-UMS-WebApp

# Delete Kubernetes  Resources using Terraform
terraform apply -destroy -auto-approve

# Delete Provider Plugins
rm -rf .terraform*

# Verify Kubernetes Resources
kubectl get pods
kubectl get svc
Observation: 
1. All UserMgmt Web App related Kubernetes resources should be deleted
``` 

## Step-19: Clean-Up - EBS CSI Driver AddOn Uninstall
```t
# Change Directory
cd 18-EBS-CSI-Install-using-EKS-AddOn/02-ebs-addon-terraform-manifests

# Delete Kubernetes  Resources using Terraform
terraform apply -destroy -auto-approve

# Delete Provider Plugins
rm -rf .terraform*

# Verify Kubernetes Resources
kubectl -n kube-system get pods
Observation: 
1. All EBS CSI Driver related Kubernetes resources should be deleted
``` 

## Step-20: Clean-Up - EKS Cluster (Optional)
- If we are continuing to next section immediately ignore this step, else delete EKS Cluster to save cost.
```t
# Change Directory
cd 18-EBS-CSI-Install-using-EKS-AddOn/01-ekscluster-terraform-manifests

# Delete Kubernetes  Resources using Terraform
terraform apply -destroy -auto-approve

# Delete Provider Plugins
rm -rf .terraform*
``` 

