---
title: AWS EKS Ingress Internal LB with Terraform
description: Learn AWS EKS Ingress Internal LB with Terraform
---

## Step-01: Introduction
- Create Internal Application Load Balancer using Ingress
- To test the Internal LB, use the `curl-pod`
- Deploy `curl-pod`
- Connect to `curl-pod` and test Internal LB from `curl-pod`

## Step-02: Update Ingress Scheme annotation to Internal
- **File Name:** `04-kube-manifests-ingress-InternalLB/04-ALB-Ingress-Internal-LB.yml`
```yaml
    # Creates Internal Application Load Balancer
    alb.ingress.kubernetes.io/scheme: internal 
```

## Step-03: Deploy all Application Kubernetes Manifests and Verify
```t
# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-ingress-InternalLB/

# Verify Ingress Resource
kubectl get ingress

# Verify Apps
kubectl get deploy
kubectl get pods

# Verify NodePort Services
kubectl get svc
```
### Verify Load Balancer & Target Groups
- Load Balancer -  Listeneres (Verify both 80 & 443) 
- Load Balancer - Rules (Verify both 80 & 443 listeners) 
- Target Groups - Group Details (Verify Health check path)
- Target Groups - Targets (Verify all 3 targets are healthy)

## Step-04: How to test this Internal Load Balancer? 
- We are going to deploy a `curl-pod` in EKS Cluster
- We connect to that `curl-pod` in EKS Cluster and test using `curl commands` for our sample applications load balanced using this Internal Application Load Balancer


## Step-05: curl-pod Kubernetes Manifest
- **File Name:** `05-kube-manifests-curl/01-curl-pod.yml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-pod
spec:
  containers:
  - name: curl
    image: curlimages/curl 
    command: [ "sleep", "600" ]
```

## Step-06: Deploy curl-pod and Verify Internal LB
```t
# Deploy curl-pod
kubectl apply -f 05-kube-manifests-curl/

# Will open up a terminal session into the container
kubectl exec -it curl-pod -- sh

# We can now curl external addresses or internal services:
curl http://google.com/
curl <INTERNAL-INGRESS-LB-DNS>

# Default Backend Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com

# App1 Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com/app1/index.html

# App2 Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com/app2/index.html

# App3 Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com
```


## Step-07: Clean Up
```t
# Delete Manifests
kubectl delete -f 04-kube-manifests-ingress-InternalLB
kubectl delete -f 05-kube-manifests-curl/
```


## Step-08: Review Terraform Manifests 
- **Project Folder:** 06-ingress-InternalLB-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app1-deployment.tf
5. c5-kubernetes-app2-deployment.tf
6. c6-kubernetes-app3-deployment.tf
7. c7-kubernetes-app1-nodeport-service.tf
8. c8-kubernetes-app2-nodeport-service.tf
9. c9-kubernetes-app3-nodeport-service.tf


## Step-09: c10-kubernetes-ingress-service.tf
- **Project Folder:** 06-ingress-InternalLB-terraform-manifests
- We are going to change the `scheme` annotation to `internal
```t
    # Change from Internet Facing to Internal
    "alb.ingress.kubernetes.io/scheme" = "internal"
```
- **Complete Ingress Service Terraform Manifest**
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress-internal-lb-demo"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-internal-lb-demo"
      # Ingress Core Settings
      # Creates External Application Load Balancer      
      #"alb.ingress.kubernetes.io/scheme" = "internet-facing"
      # Creates Internal Application Load Balancer
      "alb.ingress.kubernetes.io/scheme" = "internal"
      # Health Check Settings
      "alb.ingress.kubernetes.io/healthcheck-protocol" =  "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" = "traffic-port"
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = 15
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = 5
      "alb.ingress.kubernetes.io/success-codes" = 200
      "alb.ingress.kubernetes.io/healthy-threshold-count" = 2
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = 2
    }    
  }
  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class        
    # Default Rule: Route requests to App3 if the DNS is "tfdefault101.stacksimplify.com"        
    default_backend {
      service {
        name = kubernetes_service_v1.myapp3_np_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.myapp1_np_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/app1"
          path_type = "Prefix"
        }

        path {
          backend {
            service {
              name = kubernetes_service_v1.myapp2_np_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/app2"
          path_type = "Prefix"
        }
      }
    }
  }
}
```
## Step-10: c11-kubernetes-curl-pod-for-testing-InternalLB.tf
- **Project Folder:** 06-ingress-InternalLB-terraform-manifests
- We are going to deploy a simple curl-pod to test the access to our Internal Load Balancers

## Step-11: Execute Terraform Commands
```t
# Change Directory 
cd 06-ingress-InternalLB-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-12: Verify Ingress Service
```t
# Verify Ingress Resource
kubectl get ingress

# Verify Apps
kubectl get deploy
kubectl get pods

# Verify NodePort Services
kubectl get svc

# Verify Internal AWS Application Load Balancer 
1. Login to AWS Mgmt Console
2. Go to Services -> EC2 -> Load Balancers -> Load Balancer
3. Go to Services -> EC2 -> Load Balancers -> Target Groups
```

## Step-13: Connect to curl-pod and Test the Applications load balanced using Internal Load Balancers
```t
# Will open up a terminal session into the container
kubectl exec -it curl-pod -- sh

# We can now curl external addresses or internal services:
curl http://google.com/
curl <INTERNAL-INGRESS-LB-DNS>

# Default Backend Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com

# App1 Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com/app1/index.html

# App2 Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com/app2/index.html

# App3 Curl Test
curl internal-ingress-internal-lb-1839544354.us-east-1.elb.amazonaws.com
```

## Step-14: Clean-Up Ingress
```t
# Change Directory 
cd 06-ingress-InternalLB-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-15: Don't Clean-Up EKS Cluster, LBC Controller and ExternalDNS
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





