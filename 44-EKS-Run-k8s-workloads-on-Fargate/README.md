---
title: AWS EKS Fargate Profile with Terraform
description: Learn to create AWS EKS Kubernetes Fargate Profiles with Terraform
---
## Step-01: Introduction
- Run EKS Workloads on AWS Fargate

## Step-02: Review Terraform Manifests
- Update all the Kubernetes Resources (Deployments, Node Port Services, Ingress Service) with ` namespace = "fp-ns-app1"`.
- All the Kubernetes Workloads (App1, App2 and App3) pods will be scheduled on Fargate Nodes
- **Project Folder:** 06-run-on-fargate-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app1-deployment.tf
5. c5-kubernetes-app2-deployment.tf
6. c6-kubernetes-app3-deployment.tf
```t
# Custom Requests for Fargate Pods in a Kubernetes Deployment 
          resources {
            requests = {
              "cpu" = "1000m"
              "memory" = "2048Mi" 
            }
            limits = {
              "cpu" = "2000m"
              "memory" = "4096Mi"
            }
          }
```
7. c7-kubernetes-app1-nodeport-service.tf
8. c8-kubernetes-app2-nodeport-service.tf
9. c9-kubernetes-app3-nodeport-service.tf
10. c10-kubernetes-ingress-service.tf
11. c11-acm-certificate.tf

## Step-03: Execute Terraform Commands
```t
# Change Directory
cd 06-run-on-fargate-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-04: Verify Kubernetes Resources
```t
# Verify Nodes
kubectl get nodes
Observation:
1. New Fargate nodes will be created

# Verify Deployments
kubectl -n fp-ns-app1 get deploy

# Verify Pods
kubectl -n fp-ns-app1 get pods

# Verify Services
kubectl -n fp-ns-app1 get svc

# Verify Ingress Service
kubectl -n fp-ns-app1 get ingress

# Access Application
http://fargate-profile-demo-501.stacksimplify.com
http://fargate-profile-demo-501.stacksimplify.com/app1/index.html
http://fargate-profile-demo-501.stacksimplify.com/app2/index.html
```

## Step-05: Review Pod Memory and CPU - Default Allocated
- [Fargate Pod vCPU Value vs Memory Value](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html)
```t
# List Pods
kubectl -n fp-ns-app1 get pods

# Describe Pod
kubectl -n fp-ns-app1 describe pod <APP1-POD-NAME>
kubectl -n fp-ns-app1 describe pod app1-nginx-deployment-777cddb9b4-rhrpq
Observation:
1. Review Annotations section

# Sample: Default Capacity Allocated
Annotations:          CapacityProvisioned: 0.25vCPU 0.5GB
```
## Step-06: Review Pod Memory and CPU - Custom Kubernetes Requests and Limits
```t
# List Pods
kubectl -n fp-ns-app1 get pods

# Describe Pod
kubectl -n fp-ns-app1 describe pod <APP3-POD-NAME>
kubectl -n fp-ns-app1 describe pod app3-nginx-deployment-b54c5b6bd-m6hh9
Observation:
1. Review Annotations section

# Sample: Customized Capacity Allocated for Fargate Pod
CapacityProvisioned: 1vCPU 3GB
```

## Step-07: Clean-Up
```t
# Change Directory
cd 06-run-on-fargate-terraform-manifests

# Destroy Resources
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-08: Clean-Up EKS Cluster, LBC Controller, ExternalDNS and Fargate Profile
- Destroy the Terraform Projects in below four folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-lbc-install-terraform-manifests
- **Terraform Project Folder:** 03-externaldns-install-terraform-manifests
- **Terraform Project Folder:** 04-fargate-profiles-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 04-fargate-profiles-terraform-manifests
  - 03-externaldns-install-terraform-manifests
  - 02-lbc-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Delete Fargate Profile
# Change Directory
cd 04-fargate-profiles-terraform-manifests

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



