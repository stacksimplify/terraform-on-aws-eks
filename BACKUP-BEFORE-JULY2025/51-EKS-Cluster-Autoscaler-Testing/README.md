---
title: AWS EKS Cluster Autoscaler - Testing
description: Test AWS EKS Cluster Autoscaler - Testing Scale Up and Scale Down
---

## Step-01: Introduction
- We are going to test the AWS EKS Cluster Autoscaler Scale Up and Scale Down Events

## Step-02: Project-03: Review YAML Manifest
- **Project Folder:** 03-cluster-autoscaler-sample-app
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ca-demo-deployment
  labels:
    app: ca-nginx
spec:
  replicas: 30
  selector:
    matchLabels:
      app: ca-nginx
  template:
    metadata:
      labels:
        app: ca-nginx
    spec:
      containers:
      - name: ca-nginx
        image: stacksimplify/kubenginx:1.0.0
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "200m"       
            memory: "200Mi"            
---
apiVersion: v1
kind: Service
metadata:
  name: ca-demo-service-nginx
  labels:
    app: ca-nginx
spec:
  type: LoadBalancer
  selector:
    app: ca-nginx
  ports:
  - port: 80
    targetPort: 80
    #nodePort: 31233
```

## Step-03: Deploy Cluster Autoscaler Sample App
```t
# List Nodes  (before deploying sample app)
kubectl get nodes

# Deploy Cluster Autoscaler Sample Application
kubectl apply -f 03-cluster-autoscaler-sample-app/

# List Pods
kubectl get pods
Observation: 
1. Few pods will be in pending state due to resources not available on current EKS Worker nodes
2. Wait for 3 to 5 mins

# List Nodes
kubectl get nodes 
Observation:
1. New node will be created by Cluster Autoscaler
2. Scale Up Event (2 nodes increased to 3 nodes)

# List Pods
kubectl get pods
Observation: 
1. All the 30 pods state should be changed to running
```

## Step-04: Change the Number of Replicas to 5
- **File Location:** `03-cluster-autoscaler-sample-app/cluster-autoscaler-sample-app.yaml`
```yaml
# Before Change
  replicas: 30

# After Change
  replicas: 5  
```

## Step-05: Deploy to Test Scale-Down Event
```t
# Deploy updated Replicase
kubectl apply -f 03-cluster-autoscaler-sample-app/

# List Pods
kubectl get pods
Observation:
1. 30 pods should come down to 5 pods
2. Wait for 12 to 15 minutes

# List Nodes
kubectl get nodes
Observation:
1. 3 nodes should be scaled down to 2 nodes 
```

## Step-06: Delete Cluster Autoscaler Sample App
```t
# Delete Cluster Autoscaler Sample App
kubectl delete -f 03-cluster-autoscaler-sample-app/
```

## Step-07: Don't Clean-Up EKS Cluster and Cluster Autoscaler
- Dont destroy the Terraform Projects in below two folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-cluster-autoscaler-install-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 02-cluster-autoscaler-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Destroy  Cluster Autoscaler
# Change Directroy
cd 02-cluster-autoscaler-install-terraform-manifests

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
