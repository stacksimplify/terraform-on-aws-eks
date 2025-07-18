---
title: AWS EKS Fargate Mount EFS with Terraform
description: Learn to Automate AAWS EKS Fargate Mount EFS with Terraform
---

## Step-01: Introduction
- Mount EFS File System on Workloads Running on AWS Fargate
- Test both Static and Dynamic Provisioning

### Pre-requisites
- EKS Cluster created and ready (01-ekscluster-terraform-manifests)
- EFS CSI Driver installed and ready (02-efs-install-terraform-manifests)

## Step-02: Project-03: Review Terraform Manifests
- **Project Folder:** 03-fargate-profiles-terraform-manifests
- This a project from **Section-43** `43-EKS-Fargate-Profiles/04-fargate-profiles-terraform-manifests`

## Step-03: Create Fargate Profile
```t
# Change Directory
cd 03-fargate-profiles-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# List Fargate Profiles
aws eks list-fargate-profiles --cluster <CLUSTER_NAME>
aws eks list-fargate-profiles --cluster hr-dev-eksdemo1
```

## Step-03: Project-04: Review Terraform Manifests
- **Project Folder:** 04-efs-static-prov-terraform-manifests
- This a project from **Section-47** `47-EKS-EFS-Static-Provisioning/03-efs-static-prov-terraform-manifests`
- Following Kubernetes Resources will be created in namespace `fp-ns-app1`
```t
# Add Namespace for the Kubernetes Resources in this Demo
    namespace = "fp-ns-app1"    
```
1. c4-03-persistent-volume-claim.tf
2. c5-write-to-efs-pod.tf
3. c6-01-myapp1-deployment.tf
4. c6-02-myapp1-loadbalancer-service.tf
5. c6-03-myapp1-network-loadbalancer-service.tf


## Step-04: Deploy EFS Sample App on AWS Fargate
```t
# Change Directory
04-efs-static-prov-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-05: Verify Kubernetes Resources
```t
# Verify Storage Class
kubectl get sc

# Verify PVC (Persistent Volume Claim)
kubectl -n fp-ns-app1 get pvc

# Verify PV (Persistent Volume)
kubectl get pv

# List Nodes
kubectl get nodes
Observation:
1. You should see fargate nodes in addition to regular EC2 Worker Nodes

# List Pods
kubectl get pods -o wide
Observation:
1. You should see these pods scheduled on Fargate Nodes 
```

## Step-06: Connect to efs-write-app Kubernetes pods and Verify 
```t
# efs-write-app - Connect to Kubernetes Pod
kubectl -n fp-ns-app1 exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl -n fp-ns-app1  exec --stdin --tty efs-write-app  -- /bin/sh
cd /data
ls
tail -f efs-static.txt
```

## Step-07: Connect to myapp1 Kubernetes pods and Verify 
```t
# Verify Fargate Nodes
kubectl get nodes

# List Pods
kubectl -n fp-ns-app1 get pods 
kubectl -n fp-ns-app1 get pods -o wide 

# List Services
kubectl -n fp-ns-app1 get svc

# myapp1 POD1 - Connect to Kubernetes Pod
kubectl -n fp-ns-app1 exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl -n fp-ns-app1 exec --stdin --tty myapp1-667d8656cc-88l57 -- /bin/sh
cd /usr/share/nginx/html/efs
ls
tail -f efs-static.txt

# myapp1 POD2 - Connect to Kubernetes Pod
kubectl -n fp-ns-app1 exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl -n fp-ns-app1 exec --stdin --tty myapp1-667d8656cc-8p9l4   -- /bin/sh
cd /usr/share/nginx/html/efs
ls
tail -f efs-static.txt
```

## Step-08: Access Application
```t
# Get DNS Names of Kubernetes Services
kubectl -n fp-ns-app1 get svc

# Access Application
http://<CLB-DNS-URL>/efs/efs-dynamic.txt
http://<NLB-DNS-URL>/efs/efs-dynamic.txt
```

## Step-09: Clean-Up
```t
# Change Directory
cd 04-efs-static-prov-terraform-manifests

# Destroy Resources
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-10: Project-05: Review Terraform Manifests
- **Project Folder:** 05-efs-dynamic-prov-terraform-manifests
- This a project from **Section-48** `48-EKS-EFS-Dynamic-Provisioning/03-efs-dynamic-prov-terraform-manifests`
- Following Kubernetes Resources will be created in namespace `fp-ns-app1`
```t
# Add Namespace for the Kubernetes Resources in this Demo
    namespace = "fp-ns-app1"    
```
1. c4-03-persistent-volume-claim.tf
2. c5-write-to-efs-pod.tf
3. c6-01-myapp1-deployment.tf
4. c6-02-myapp1-loadbalancer-service.tf
5. c6-03-myapp1-network-loadbalancer-service.tf

## Step-11: Deploy EFS Sample App on AWS Fargate
```t
# Change Directory
05-efs-dynamic-prov-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-12: Verify Kubernetes Resources
```t
# Verify Storage Class
kubectl get sc

# Verify PVC (Persistent Volume Claim)
kubectl -n fp-ns-app1 get pvc

# Verify PV (Persistent Volume)
kubectl get pv

# List Nodes
kubectl get nodes
Observation:
1. You should see fargate nodes in addition to regular EC2 Worker Nodes

# List Pods
kubectl get pods -o wide
Observation:
1. You should see these pods scheduled on Fargate Nodes 
```

## Step-13: Connect to efs-write-app Kubernetes pods and Verify 
```t
# efs-write-app - Connect to Kubernetes Pod
kubectl -n fp-ns-app1 exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl -n fp-ns-app1  exec --stdin --tty efs-write-app  -- /bin/sh
cd /data
ls
tail -f efs-dynamic.txt
```

## Step-14: Connect to myapp1 Kubernetes pods and Verify 
```t
# Verify Fargate Nodes
kubectl get nodes

# List Pods
kubectl -n fp-ns-app1 get pods 
kubectl -n fp-ns-app1 get pods -o wide 

# List Services
kubectl -n fp-ns-app1 get svc

# myapp1 POD1 - Connect to Kubernetes Pod
kubectl -n fp-ns-app1 exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl -n fp-ns-app1 exec --stdin --tty myapp1-667d8656cc-88l57 -- /bin/sh
cd /usr/share/nginx/html/efs
ls
tail -f efs-dynamic.txt

# myapp1 POD2 - Connect to Kubernetes Pod
kubectl -n fp-ns-app1 exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl -n fp-ns-app1 exec --stdin --tty myapp1-667d8656cc-8p9l4   -- /bin/sh
cd /usr/share/nginx/html/efs
ls
tail -f efs-dynamic.txt
```

## Step-15: Access Application
```t
# Get DNS Names of Kubernetes Services
kubectl -n fp-ns-app1 get svc

# Access Application
http://<CLB-DNS-URL>/efs/efs-dynamic.txt
http://<NLB-DNS-URL>/efs/efs-dynamic.txt
```

## Step-16: Clean-Up
```t
# Change Directory
cd 05-efs-dynamic-prov-terraform-manifests

# Destroy Resources
terraform apply -destroy -auto-approve
rm -rf .terraform*
```


## Step-11: Clean-Up EKS Cluster, EFS CSI Driver
- Destroy the Terraform Projects in below two folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-efs-install-terraform-manifests
-  **Terraform Project Folder:** 03-fargate-profiles-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 03-fargate-profiles-terraform-manifests
  - 02-efs-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Delete Fargate Profile
# Change Directory
cd 03-fargate-profiles-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve
##############################################################
## Delete EFS CSI Driver
# Change Directory
cd 02-efs-install-terraform-manifests

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
- [AWS IAM OIDC Connect Provider - Step-3](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html)
- [AWS EFS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)
- [AWS Caller Identity Datasource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)
- [HTTP Datasource](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http)
- [AWS IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [AWS IAM Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
- [AWS EFS CSI Docker Images across Regions](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html)
- [To find latestEFS CSI Driver GIT Repo](https://github.com/kubernetes-sigs/aws-efs-csi-driver/)

