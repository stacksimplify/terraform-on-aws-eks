---
title: AWS EKS Ingress Cross Namespaces with Terraform
description: Learn AWS EKS Ingress Cross Namespaces with Terraform
---

## Step-01: Introduction
- Create Ingress Services in Multiple Namespaces and merged to create to create a Single Application Load Balancer with Ingress Groups concept. 

## Step-02: Review App1 Ingress Manifest - Key Lines
- **File Name:** `04-kube-manifests-ingress-cross-ns/app1/02-App1-Ingress.yml`
```yaml
    # Ingress Groups
    alb.ingress.kubernetes.io/group.name: myapps.web
    alb.ingress.kubernetes.io/group.order: '10'
```

## Step-03: Review App2 Ingress Manifest - Key Lines
- **File Name:** `04-kube-manifests-ingress-cross-ns/app2/02-App2-Ingress.yml`
```yaml
    # Ingress Groups
    alb.ingress.kubernetes.io/group.name: myapps.web
    alb.ingress.kubernetes.io/group.order: '20'
```

## Step-04: Review App3 Ingress Manifest - Key Lines
- **File Name:** `04-kube-manifests-ingress-cross-ns/app3/02-App3-Ingress.yml`
```yaml
    # Ingress Groups
    alb.ingress.kubernetes.io/group.name: myapps.web
    alb.ingress.kubernetes.io/group.order: '30'
```

## Step-05: Create Namespaces
- **Files:** 
  - 04-kube-manifests-ingress-cross-ns/app1/00-namespace.yml
  - 04-kube-manifests-ingress-cross-ns/app2/00-namespace.yml
  - 04-kube-manifests-ingress-cross-ns/app3/00-namespace.yml
```yaml
# Namespace: ns-app1
apiVersion: v1
kind: Namespace
metadata: 
  name: ns-app1

# Namespace: ns-app2
apiVersion: v1
kind: Namespace
metadata: 
  name: ns-app2

# Namespace: ns-app3
apiVersion: v1
kind: Namespace
metadata: 
  name: ns-app3
```

## Step-06: Update Deployment, NodePort Service and Ingress Service as namespaced resources
- **Deployment and NodePort Service:** Update Namespace in resource metadata
  - 04-kube-manifests-ingress-cross-ns/app1/01-Nginx-App1-Deployment-and-NodePortService.yml
  - 04-kube-manifests-ingress-cross-ns/app2/01-Nginx-App2-Deployment-and-NodePortService.yml
  - 04-kube-manifests-ingress-cross-ns/app3/01-Nginx-App3-Deployment-and-NodePortService.yml

- **Ingress Service:** Update Namespace in resource metadata
  - 04-kube-manifests-ingress-cross-ns/app1/02-App1-Ingress.yml
  - 04-kube-manifests-ingress-cross-ns/app2/02-App2-Ingress.yml
  - 04-kube-manifests-ingress-cross-ns/app3/02-App3-Ingress.yml

## Step-07: Deploy Apps with two Ingress Resources
```t
# Deploy both Apps
kubectl apply -R -f 04-kube-manifests-ingress-cross-ns/

# Verify Pods
kubectl get pods -n ns-app1
kubectl get pods -n ns-app2
kubectl get pods -n ns-app3

# Verify Ingress
kubectl  get ingress -n ns-app1
kubectl  get ingress -n ns-app2
kubectl  get ingress -n ns-app3
Observation:
1. Three Ingress resources will be created with same ADDRESS value
2. Three Ingress Resources are merged to a single Application Load Balancer as those belong to same Ingress group "myapps.web"
```

## Step-08: Verify on AWS Mgmt Console
- Go to Services -> EC2 -> Load Balancers 
- Verify Routing Rules for `/app1` and `/app2` and `default backend`

## Step-09: Verify by accessing in browser
```t
# Web URLs
http://ingress-crossns-demo.stacksimplify.com/app1/index.html
http://ingress-crossns-demo.stacksimplify.com/app2/index.html
http://ingress-crossns-demo.stacksimplify.com
```

## Step-10: Clean-Up
```t
# Delete Apps from k8s cluster
kubectl delete -R -f 04-kube-manifests-ingress-cross-ns/

## Verify Route53 Record Set to ensure our DNS records got deleted
- Go to Route53 -> Hosted Zones -> Records 
- The below records should be deleted automatically
  - ingress-crossns-demo.stacksimplify.com
```

## Step-11: Review Terraform Manifests 
- **Project Folder:** 05-ingress-cross-ns-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c14-acm-certificate.tf

## Step-12: c13-kubernetes-namespaces.tf
- **Project Folder:** 05-ingress-cross-ns-terraform-manifests
```t
# Resource: Kubernetes Namespace ns-app1
resource "kubernetes_namespace_v1" "ns_app1" {
  metadata {
    name = "ns-app1"
  }
}

# Resource: Kubernetes Namespace ns-app2
resource "kubernetes_namespace_v1" "ns_app2" {
  metadata {
    name = "ns-app2"
  }
}

# Resource: Kubernetes Namespace ns-app3
resource "kubernetes_namespace_v1" "ns_app3" {
  metadata {
    name = "ns-app3"
  }
}
```


## Step-13: Add Namespace for Deployments, NodePort and Ingress Service
- **Project Folder:** 05-ingress-cross-ns-terraform-manifests
1. c4-kubernetes-app1-deployment.tf
2. c5-kubernetes-app2-deployment.tf
3. c6-kubernetes-app3-deployment.tf
4. c7-kubernetes-app1-nodeport-service.tf
5. c8-kubernetes-app2-nodeport-service.tf
6. c9-kubernetes-app3-nodeport-service.tf
7. c10-kubernetes-app1-ingress-service.tf
8. c11-kubernetes-app2-ingress-service.tf
9. c12-kubernetes-app3-ingress-service.tf
```t
# Add it in every k8s resource Metadata section
# Sample
    namespace = kubernetes_namespace_v1.ns_app1.metadata[0].name    
```


## Step-14: Execute Terraform Commands
```t
# Change Directory 
cd 05-ingress-cross-ns-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-15: Verify Ingress Service
```t
# Verify Ingress Resource
kubectl get ingress -n ns-app1
kubectl get ingress -n ns-app2
kubectl get ingress -n ns-app3

# Verify Apps
kubectl get deploy -n ns-app1
kubectl get deploy -n ns-app2
kubectl get deploy -n ns-app3
kubectl get pods -n ns-app1
kubectl get pods -n ns-app2
kubectl get pods -n ns-app3

# Verify NodePort Services
kubectl get svc -n ns-app1
kubectl get svc -n ns-app2
kubectl get svc -n ns-app3
```

## Step-16: Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```

## Step-17: Verify Route53
- Go to Services -> Route53
- You should see **Record Set** added for 
  - tfingress-crossns-demo401.stacksimplify.com


## Step-18: Access Application using newly registered DNS Name
- Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup tfingress-crossns-demo401.stacksimplify.com
```
## Step-19: Access Application 
```t
# Access App1
http://tfingress-crossns-demo401.stacksimplify.com/app1/index.html

# Access App2
http://tfingress-crossns-demo401.stacksimplify.com/app2/index.html

# Access Default App (App3)
http://tfingress-crossns-demo401.stacksimplify.com
```


## Step-20: Clean-Up Ingress
```t
# Change Directory 
cd 05-ingress-cross-ns-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-21: Don't Clean-Up EKS Cluster, LBC Controller and ExternalDNS
- Dont destroy the Terraform Projects in below two folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-lbc-install-terraform-manifests
- **Terraform Project Folder:** 03-externaldns-install-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 03-externaldns-install-terraform-manifests
  - 02-lbc-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
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



