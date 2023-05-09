---
title: AWS EKS Ingress SSL Discovery TLS with Terraform
description: Implement Ingress SSL Discovery TLS so that AWS ACM Certificate will be automatically discovered and associated to Ingress Service
---


## Step-01: Introduction
- Automatically disover SSL Certificate from AWS Certificate Manager Service using `spec.tls.host`
- In this approach, with the specified domain name if we have the SSL Certificate created in AWS Certificate Manager, that certificate will be automatically detected and associated to Application Load Balancer.
- We don't need to get the SSL Certificate ARN and update it in Kubernetes Ingress Manifest
- Discovers via Ingress rule host and attaches a cert for `app102.stacksimplify.com` or `*.stacksimplify.com` to the ALB

## Step-02: Discover via Ingress "spec.tls.hosts"
```yaml
# Annotations Reference: https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-certdiscoverytls-demo
  annotations:
    # Load Balancer Name
    alb.ingress.kubernetes.io/load-balancer-name: certdiscoverytls-ingress
    # Ingress Core Settings
    #kubernetes.io/ingress.class: "alb" (OLD INGRESS CLASS NOTATION - STILL WORKS BUT RECOMMENDED TO USE IngressClass Resource)
    alb.ingress.kubernetes.io/scheme: internet-facing
    # Health Check Settings
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP 
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/success-codes: '200'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'   
    ## SSL Settings
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    #alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:180789647333:certificate/632a3ff6-3f6d-464c-9121-b9d97481a76b
    #alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-1-2017-01 #Optional (Picks default if not used)    
    # SSL Redirect Setting
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    # External DNS - For creating a Record Set in Route53
    external-dns.alpha.kubernetes.io/hostname: certdiscovery-tls-101.stacksimplify.com 
spec:
  ingressClassName: my-aws-ingress-class   # Ingress Class                  
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80     
  tls:
  - hosts:
    - "*.stacksimplify.com"
  rules:
    - http:
        paths:
          - path: /app1
            pathType: Prefix
            backend:
              service:
                name: app1-nginx-nodeport-service
                port: 
                  number: 80
    - http:
        paths:                  
          - path: /app2
            pathType: Prefix
            backend:
              service:
                name: app2-nginx-nodeport-service
                port: 
                  number: 80

# Important Note-1: In path based routing order is very important, if we are going to use  "/*", try to use it at the end of all rules.                                        
                        
# 1. If  "spec.ingressClassName: my-aws-ingress-class" not specified, will reference default ingress class on this kubernetes cluster
# 2. Default Ingress class is nothing but for which ingress class we have the annotation `ingressclass.kubernetes.io/is-default-class: "true"` 
 ```


## Step-03: Deploy all Application Kubernetes Manifests and Verify
```t
# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-SSLDiscoveryTLS/

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
- **PRIMARILY VERIFY - CERTIFICATE ASSOCIATED TO APPLICATION LOAD BALANCER**

### Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```
### Verify Route53
- Go to Services -> Route53
- You should see **Record Sets** added for 
  - certdiscovery-tls-901.stacksimplify.com 


## Step-04: Access Application using newly registered DNS Name
### Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup certdiscovery-tls-101.stacksimplify.com 
```
### Access Application using DNS domain
```t
# Access App1
http://certdiscovery-tls-101.stacksimplify.com/app1/index.html

# Access App2
http://certdiscovery-tls-101.stacksimplify.com/app2/index.html

# Access Default App (App3)
http://certdiscovery-tls-101.stacksimplify.com
```

## Step-05: Clean Up
```t
# Delete Manifests
kubectl delete -f 04-kube-manifests-SSLDiscoveryTLS/

## Verify Route53 Record Set to ensure our DNS records got deleted
- Go to Route53 -> Hosted Zones -> Records 
- The below records should be deleted automatically
  - certdiscovery-tls-101.stacksimplify.com 
```

## Step-06: Review Terraform Manifests 
- **Project Folder:** 05-ingress-SSLDiscoveryTLS-terraform-manifests
1. c1-versions.tf
```t
# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.13"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.11"
    }    
    time = {
      source = "hashicorp/time"
      version = "~> 0.7"
    }
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-on-aws-eks"
    key    = "dev/aws-lbc-ingress/terraform.tfstate"
    region = "us-east-1" 

    # For State Locking
    dynamodb_table = "dev-aws-lbc-ingress"    
  }    
}

# Time Provider
provider "time" {
  # Configuration options
}
```
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app1-deployment.tf
5. c5-kubernetes-app2-deployment.tf
6. c6-kubernetes-app3-deployment.tf
7. c7-kubernetes-app1-nodeport-service.tf
8. c8-kubernetes-app2-nodeport-service.tf
9. c9-kubernetes-app3-nodeport-service.tf
10. c11-acm-certificate.tf


## Step-07: c10-kubernetes-ingress-service.tf
- **Project Folder:** 05-ingress-SSLDiscoveryTLS-terraform-manifests
```t
# Wait 60 seconds after ACM Certificate Resource is created and changed the Certificate status to ISSUED
resource "time_sleep" "wait_60_seconds" {
  depends_on = [aws_acm_certificate.acm_cert]
  create_duration = "60s"
}

# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress" {
# This resource will create (at least) 60 seconds after aws_acm_certificate.acm_cert 
  depends_on = [time_sleep.wait_60_seconds]
  metadata {
    name = "ingress-certdiscoverytls-demo"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "certdiscoverytls-ingress"
      # Ingress Core Settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      # Health Check Settings
      "alb.ingress.kubernetes.io/healthcheck-protocol" =  "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" = "traffic-port"
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = 15
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = 5
      "alb.ingress.kubernetes.io/success-codes" = 200
      "alb.ingress.kubernetes.io/healthy-threshold-count" = 2
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = 2
      ## SSL Settings
      # Option-1: Using Terraform jsonencode Function
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTPS" = 443}, {"HTTP" = 80}])
      # Option-2: Using Terraform File Function      
      #"alb.ingress.kubernetes.io/listen-ports" = file("${path.module}/listen-ports/listen-ports.json")
      #"alb.ingress.kubernetes.io/certificate-arn" =  "${aws_acm_certificate.acm_cert.arn}"
      #"alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01" #Optional (Picks default if not used)    
      # SSL Redirect Setting
      "alb.ingress.kubernetes.io/ssl-redirect" = 443
    # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfcertdiscovery-tls-102.stacksimplify.com"
    }    
  }
  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class            
    default_backend {
      service {
        name = kubernetes_service_v1.myapp3_np_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
    # SSL Certificate Discovery using TLS
    tls {
      hosts = [ "*.stacksimplify.com" ]
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

## Step-08: Execute Terraform Commands
```t
# Change Directory 
cd 05-ingress-SSLDiscoveryTLS-terraform-manifests

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
- You should see **Record Sets** added for 
  - tfapp101.stacksimplify.com
  - tfapp201.stacksimplify.com
  - tfdefault101.stacksimplify.com

## Step-12: Access Application using newly registered DNS Name
- Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup tfapp101.stacksimplify.com
nslookup tfapp201.stacksimplify.com
nslookup tfdefault101.stacksimplify.com
```
## Step-13: Access Application 
```t
# Access App1
http://tfapp101.stacksimplify.com/app1/index.html

# Access App2
http://tfapp201.stacksimplify.com/app2/index.html

# Access Default App (App3)
http://tfdefault101.stacksimplify.com
```


## Step-14: Clean-Up Ingress
```t
# Change Directory 
cd 05-ingress-SSLDiscoveryTLS-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-15: Don't Clean-Up LBC Controller & EKS Cluster
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
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/cert_discovery/
