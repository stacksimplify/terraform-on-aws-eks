---
title: EBS Volumes Resize and Retain Concepts on EKS Cluster
description: EBS Volumes Resize and Retain Concepts on EKS Cluster using EBS CSI Driver
---

## Step-00: Introduction
- Implement the below two concepts on EKS Cluster usign EBS CSI Driver 
   - Resize EBS Volumes
   - Retain EBS Volumes 


## Pre-requisite: Verify EKS Cluster and EBS CSI Driver already Installed
### Project-01: 01-ekscluster-terraform-manifests
```t
# Change Directroy
cd 17-EBS-Resizing-on-EKS/01-ekscluster-terraform-manifests

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
### Project-02: 02-ebs-terraform-manifests
```t
# Change Directroy
cd 17-EBS-Resizing-on-EKS/02-ebs-terraform-manifests

# Terraform Initialize
terraform init

# List Terraform Resources (if already EBS CSI Driver created as part of previous section we can see those resources)
terraform state list

# Else Run below Terraform Commands
terraform validate
terraform plan
terraform apply -auto-approve

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify EBS CSI Controller and Node pods running in kube-system namespace
kubectl -n kube-system get pods
```   


## Step-01: Folder: 03-terraform-manifests-UMS-WebApp
- **File:** c4-01-storage-class.tf
- Add `allow_volume_expansion` and `reclaim_policy` settings
```t
# Resource: Kubernetes Storage Class
resource "kubernetes_storage_class_v1" "ebs_sc" {  
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = "true"  
  reclaim_policy = "Retain" # Additional Reference: https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/#why-change-reclaim-policy-of-a-persistentvolume
}
```
## Step-02: Deploy EBS Sample App - Execute TF Commands
```t
# Change Directory
cd  17-EBS-Resizing-on-EKS/03-terraform-manifests-UMS-WebApp

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```
## Step-03: Verify UMS Web App
```t
# Verify UserMgmt WebApp Pods
kubectl get pods

# List Services
kubectl get svc

# Access Usermgmt webapp
http://<CLB-DNS-URL>
http://<NLB-DNS-URL>
Username: admin101
Password: password101

# Create User admin102
Username: admin102
Password: password102
First Name: fname102
Last Name: lname102
email: email102@gmail.com
ssn: ssn102
```

## Step-04: c4-02-persistent-volume-claim.tf
- **Folder:** `17-EBS-Resizing-on-EKS/03-terraform-manifests-UMS-WebApp`
```t
# Change Storage from
        storage = "4Gi"

# Change Storage To
        storage = "6Gi"        
```

## Step-05: Execute Terraform Commands
```t
# Verify before change: EBS Volume using Mgmt Console
Go to Services -> Elastic Block Store -> Volumes

# Verify before change: using kubectl
kubectl get pvc
kubectl get pv

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify after change: EBS Volume using Mgmt Console
Go to Services -> Elastic Block Store -> Volumes

# Verify after change: using kubectl
kubectl get pvc
kubectl get pv

# Access Usermgmt webapp and verify if any impact to DB
http://<CLB-DNS-URL>
http://<NLB-DNS-URL>
Username: admin101
Password: password101

# You can also try by connecting MySQL DB and verify
# Connect to MySQL Database 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -pdbpassword11

# Verify usermgmt schema got created which we provided in ConfigMap
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
```

## Step-06: CleanUp - 03-terraform-manifests-UMS-WebApp
```t
# Change Directory
cd 17-EBS-Resizing-on-EKS/03-terraform-manifests-UMS-WebApp

# Terraform Destroy
terraform destroy -auto-approve

# Delete Provider Plugin Files
rm -rf .terraform* 
```

## Step-07: Verify Persistent Volume as we have put Retain setting
- Storage Class Setting in `c4-01-storage-class.tf` is `reclaim_policy = "Retain"`
```t
# Verify PVC
kubectl get pvc

# Verify PV
kubectl get pv
kubectl get pv -o yaml
Observation:
1. EBS Volume is not deleted when Storage Class and PVC were destroyed.
2. It will be the `Status: Released` mode as Persistent Volume

# Verify the same on AWS mgmt Console
Go to Services -> Elastic Block Store -> Volumes
Observation: 
1. Volume should be present here

# Delete PV
kubectl get pv
kubectl delete pv <PV-NAME>

# Verify the same on AWS mgmt Console
Go to Services -> Elastic Block Store -> Volumes
Observation: 
1. Volume should be present here

# Manually delete the EBS Volume
Go to Services -> Elastic Block Store -> Volumes
Select and Delete Volume
``` 

## Step-08: CleanUp - 02-ebs-terraform-manifests
```t
# Change Directory
cd 17-EBS-Resizing-on-EKS/02-ebs-terraform-manifests

# List Terraform Resources
terraform state list

# Terraform Destroy
terraform apply -destroy -auto-approve

# Delete Provider Plugin Files
rm -rf .terraform* 
```

## Step-09: CleanUp - 01-ekscluster-terraform-manifests (Optional)
- Destroying EKS Cluster is optional in this step, if we are doing the next section related demo today. 
```t
# Change Directory
cd 17-EBS-Resizing-on-EKS/01-ekscluster-terraform-manifests

# List Terraform Resources
terraform state list

# Terraform Destroy
terraform apply -destroy -auto-approve

# Delete Provider Plugin Files
rm -rf .terraform* 
```