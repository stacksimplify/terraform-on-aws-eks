---
title: AWS EKS Horizontal Pod Autoscaler with Terraform
description: Learn to implement AWS EKS Horizontal Pod Autoscaler with Terraform
---

## Step-01: Introduction
- Install Metrics Server
- Implement a Sample Demo with HPA

### Pre-requisites
- EKS Cluster is created and ready for use
```t
# Change Directory
01-ekscluster-terraform-manifests

# Create EKS Cluster
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# If EKS Cluster already create as per previous sections JUST VERIFY
terraform init
terraform state list


# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```

## Step-02: Project-02: Review Terraform Manifests
- **Project Folder:** 02-k8s-metrics-server-terraform-manifests
1. c1-versions.tf
  - Create DynamoDB Table `dev-eks-metrics-server`
2. c2-remote-state-datasource.tf
3. c3-01-generic-variables.tf
4. c3-02-local-values.tf
5. c4-01-helm-provider.tf

## Step-03: c4-02-metrics-server-install.tf
- **Project Folder:** 02-k8s-metrics-server-terraform-manifests
```t
# Install Kubernetes Metrics Server using HELM
# Resource: Helm Release 
resource "helm_release" "metrics_server_release" {
  name       = "${local.name}-metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace = "kube-system"   
}
```
## Step-04: c4-03-metrics-server-outputs.tf
- **Project Folder:** 02-k8s-metrics-server-terraform-manifests
```t
# Helm Release Outputs
output "metrics_server_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.metrics_server_release.metadata
}
```
## Step-05: Execute Terraform Commands
- **Project Folder:** 02-k8s-metrics-server-terraform-manifests
```t
# Verify if metrics for pods are displayed (Before install of Metrics Server)
kubectl top pods -n kube-system

# Change Directory 
cd 02-k8s-metrics-server-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-06: Verify Metrics Server
```t
# List Deployments
kubectl -n kube-system get deploy

# List Pods
kubectl -n kube-system get pods

# Verify Metrics Server Logs
kubectl -n kube-system logs -f <POD-NAME>
kubectl -n kube-system logs -f hr-dev-metrics-server-664b99d749-vgnqd

# Verify if metrics for pods are displayed (After install of Metrics Server)
kubectl top pods -n kube-system
```

## Step-07: Project-03: Review Sample App Manifests
- Primarily review `HorizontalPodAutoscaler` Resource in file `03-hpa-demo-yaml`
- **Project Folder:** 03-hpa-demo-yaml
1. 01-deployment.yaml
2. 02-service.yaml
3. 03-hpa-demo-yaml
```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
 name: hpa-app3
spec:
 scaleTargetRef:
   apiVersion: apps/v1
   kind: Deployment
   name: app3-nginx-deployment
 minReplicas: 1
 maxReplicas: 10
 targetCPUUtilizationPercentage: 50
```

## Step-08: Deploy Sample App and Verify using kubectl
```t
# Change Directory
cd 52-EKS-Horizontal-Pod-Autoscaler 

# Deploy Sample
kubectl apply -f 03-hpa-demo-yaml/

# List Pods
kubectl get pods
Observation: 
1. Currently only 1 pod is running

# List HPA
kubectl get hpa

## Sample Output
Kalyans-MacBook-Pro:52-EKS-Horizontal-Pod-Autoscaler kdaida$ kubectl get hpa
NAME       REFERENCE                          TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-app3   Deployment/app3-nginx-deployment   0%/50%    1         10        1          2m1s
Kalyans-MacBook-Pro:52-EKS-Horizontal-Pod-Autoscaler kdaida$ 

# Run Load Test (New Terminal)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://app3-nginx-cip-service; done"

# List HPA (Wait for few mins)
kubectl get hpa

# List Pods
kubectl get pods

# Clean-Up
kubectl delete -f 03-hpa-demo-yaml/
kubectl delete pod load-generator
```

## Step-09: Project-04: Review Terraform Manifests
- **Project Folder:** 04-hpa-demo-terraform-manifests
1. c1-versions.tf
  - Create DynamoDB Table `dev-hpa-demo-app`
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app3-deployment.tf
5. c5-kubernetes-app3-clusterip-service.tf

## Step-10: c6-hpa-resource.tf
- **Project Folder:** 04-hpa-demo-terraform-manifests
```t
resource "kubernetes_horizontal_pod_autoscaler_v1" "hpa_myapp3" {
  metadata {
    name = "hpa-app3"
  }
  spec {
    max_replicas = 10
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.myapp3.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}
```
## Step-11: Execute Terraform Commands
- **Project Folder:** 04-hpa-demo-terraform-manifests
```t
# Change Directory 
cd 04-hpa-demo-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-12: Verify Kubernetes Resources and Perform Load Test
```t
# List Pods
kubectl get pods
Observation: 
1. Currently only 1 pod is running

# List HPA
kubectl get hpa

# Run Load Test (New Terminal)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://app3-nginx-cip-service; done"

# List HPA (after few mins)
kubectl get hpa

## Sample output
Kalyans-MacBook-Pro:04-hpa-demo-terraform-manifests kdaida$ kubectl get hpa
NAME       REFERENCE                          TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-app3   Deployment/app3-nginx-deployment   169%/50%   1         10        5          3m42s

# List Pods (SCALE UP EVENT)
kubectl get pods
Observation:
1. New pods will be created to reduce the CPU spikes

# List HPA (after few mins - approx 10 mins)
kubectl get hpa

# List Pods (SCALE IN EVENT)
kubectl get pods
Observation:
1. Only 1 pod should be running
```

## Step-13: Clean-Up
```t
# Delete Load Generator Pod which is in Error State
kubectl delete pod load-generator

# Change Directory 
cd 04-hpa-demo-terraform-manifests

# Terraform Destroy 
terraform apply -destroy -auto-approve
rm -rf .terraform*
```





## References
- [Metrics Server Helm Chart](https://artifacthub.io/packages/helm/metrics-server/metrics-server)
- [Metrics Server Git Repo](https://github.com/kubernetes-sigs/metrics-server/)
