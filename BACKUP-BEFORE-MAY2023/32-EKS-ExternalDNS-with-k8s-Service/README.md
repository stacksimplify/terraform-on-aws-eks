---
title: AWS EKS Kubernetes Service, ExternalDNS with Terraform
description: Learn to update AWS Route53 records using ExternalDNS in Kubernetes Service on AWS EKS Cluster
---


## Step-01: Introduction
- We will create a Kubernetes Service of `type: LoadBalancer`
- We will annotate that Service with external DNS hostname `external-dns.alpha.kubernetes.io/hostname: externaldns-k8s-service-demo101.stacksimplify.com` which will register the DNS in Route53 for that respective load balancer

## Step-02: 02-Nginx-App1-LoadBalancer-Service.yml
- **Project Folder:** 04-kube-manifests-k8sService-externaldns
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-nginx-loadbalancer-service
  labels:
    app: app1-nginx
  annotations:
#Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
    alb.ingress.kubernetes.io/healthcheck-path: /app1/index.html
    external-dns.alpha.kubernetes.io/hostname: extdns-k8s-service-demo101.stacksimplify.com
spec:
  type: LoadBalancer
  selector:
    app: app1-nginx
  ports:
    - port: 80
      targetPort: 80
```
## Step-03: Deploy & Verify

### Deploy & Verify
```t
# Change Directory
cd 32-EKS-ExternalDNS-with-k8s-Service

# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-k8sService-externaldns/

# Verify Apps
kubectl get deploy
kubectl get pods

# Verify Service
kubectl get svc
```
### Verify Load Balancer 
- Go to EC2 -> Load Balancers -> Verify Load Balancer Settings

### Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```
### Verify Route53
- Go to Services -> Route53
- You should see **Record Sets** added for `extdns-k8s-service-demo101.stacksimplify.com`


## Step-04: Access Application using newly registered DNS Name
### Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup extdns-k8s-service-demo101.stacksimplify.com
```
### Access Application using DNS domain
```t
# HTTP URL
http://extdns-k8s-service-demo101.stacksimplify.com/app1/index.html
```

## Step-05: Clean Up
```t
# Delete Manifests
kubectl delete -f 04-kube-manifests-k8sService-externaldns/

## Verify Route53 Record Set to ensure our DNS records got deleted
- Go to Route53 -> Hosted Zones -> Records 
- The below records should be deleted automatically
  - extdns-k8s-service-demo101.stacksimplify.com
```


## Step-06: Review Terraform Manifests 
- **Project Folder:** 05-k8sService-externaldns-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app1-deployment.tf

## Step-07: c5-kubernetes-app1-loadbalancer-service.tf
- **Project Folder:** 05-k8sService-externaldns-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "myapp1_np_service" {
  metadata {
    name = "app1-nginx-loadbalancer-service"
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app1/index.html"
      "external-dns.alpha.kubernetes.io/hostname" = "tfextdns-k8s-service-demo101.stacksimplify.com"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
```

## Step-08: Execute Terraform Commands
```t
# Change Directory 
cd 05-k8sService-externaldns-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-09: Verify Ingress Service
```t
# Verify Ingress Resource
kubectl get ingress

# Verify Apps
kubectl get deploy
kubectl get pods

# Verify NodePort Services
kubectl get svc
```

## Step-10: Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```

## Step-11: Verify Route53
- Go to Services -> Route53
- You should see **Record Sets** added for `tfextdns-k8s-service-demo101.stacksimplify.com`

## Step-12: Access Application using newly registered DNS Name
- Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup tfextdns-k8s-service-demo101.stacksimplify.com
```
## Step-13: Access Application 
```t
## Access Application using dnstest1 domain
# HTTP URLs (Should Redirect to HTTPS)
http://tfextdns-k8s-service-demo101.stacksimplify.com/app1/index.html
```


## Step-14: Clean-Up Ingress
```t
# Change Directory 
cd 05-k8sService-externaldns-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```


## Step-15: Don't Clean-Up LBC Controller, EKS Cluster and External DNS
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
## References
- https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/alb-ingress.md
- https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md

