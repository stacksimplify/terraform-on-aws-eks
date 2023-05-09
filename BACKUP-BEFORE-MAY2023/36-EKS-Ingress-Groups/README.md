---
title: AWS EKS Ingress Groups Automate with Terraform
description: Learn AWS EKS Ingress Groups concepts and Automate it with Terraform
---

## Step-01: Introduction
- IngressGroup feature enables you to group multiple Ingress resources together. 
- The controller will automatically merge Ingress rules for all Ingresses within IngressGroup and support them with a single ALB. 
- In addition, most annotations defined on a Ingress only applies to the paths defined by that Ingress.
- Demonstrate Ingress Groups concept with two Applications. 

## Step-02: Review App1 Ingress Manifest - Key Lines
- **File Name:** `04-kube-manifests-ingress-groups/app1/02-App1-Ingress.yml`
```yaml
    # Ingress Groups
    alb.ingress.kubernetes.io/group.name: myapps.web
    alb.ingress.kubernetes.io/group.order: '10'
```

## Step-03: Review App2 Ingress Manifest - Key Lines
- **File Name:** `04-kube-manifests-ingress-groups/app2/02-App2-Ingress.yml`
```yaml
    # Ingress Groups
    alb.ingress.kubernetes.io/group.name: myapps.web
    alb.ingress.kubernetes.io/group.order: '20'
```

## Step-04: Review App3 Ingress Manifest - Key Lines
- **File Name:** `04-kube-manifests-ingress-groups/app3/02-App3-Ingress.yml`
```yaml
    # Ingress Groups
    alb.ingress.kubernetes.io/group.name: myapps.web
    alb.ingress.kubernetes.io/group.order: '30'
```

## Step-05: Deploy Apps with two Ingress Resources
```t
# Deploy both Apps
kubectl apply -R -f 04-kube-manifests-ingress-groups/

# Verify Pods
kubectl get pods

# Verify Ingress
kubectl  get ingress
Observation:
1. Three Ingress resources will be created with same ADDRESS value
2. Three Ingress Resources are merged to a single Application Load Balancer as those belong to same Ingress group "myapps.web"
```

## Step-06: Verify on AWS Mgmt Console
- Go to Services -> EC2 -> Load Balancers 
- Verify Routing Rules for `/app1` and `/app2` and `default backend`

## Step-07: Verify by accessing in browser
```t
# Web URLs
http://ingress-groups-demo601.stacksimplify.com/app1/index.html
http://ingress-groups-demo601.stacksimplify.com/app2/index.html
http://ingress-groups-demo601.stacksimplify.com
```

## Step-08: Clean-Up
```t
# Delete Apps from k8s cluster
kubectl delete -R -f 04-kube-manifests-ingress-groups/

## Verify Route53 Record Set to ensure our DNS records got deleted
- Go to Route53 -> Hosted Zones -> Records 
- The below records should be deleted automatically
  - ingress-groups-demo601.stacksimplify.com
```


## Step-09: Review Terraform Manifests 
- **Project Folder:** 05-ingress-groups-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app1-deployment.tf
5. c5-kubernetes-app2-deployment.tf
6. c6-kubernetes-app3-deployment.tf
7. c7-kubernetes-app1-nodeport-service.tf
8. c8-kubernetes-app2-nodeport-service.tf
9. c9-kubernetes-app3-nodeport-service.tf
10. c13-acm-certificate.tf


## Step-10: c10-kubernetes-app1-ingress-service.tf
- **Project Folder:** 05-ingress-groups-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress_app1" {
  metadata {
    name = "app1-ingress"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-groups-demo"
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
      "alb.ingress.kubernetes.io/certificate-arn" =  "${aws_acm_certificate.acm_cert.arn}"    
      #"alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01" #Optional (Picks default if not used)    
      # SSL Redirect Setting
      "alb.ingress.kubernetes.io/ssl-redirect" = 443
      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfingress-groups-demo102.stacksimplify.com"
      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name" = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 10
    }    
  }

  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class        
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
      }
    }
  }
}
```

## Step-11: c11-kubernetes-app2-ingress-service.tf
- **Project Folder:** 05-ingress-groups-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress_app2" {
  metadata {
    name = "app2-ingress"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-groups-demo"
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
      "alb.ingress.kubernetes.io/certificate-arn" =  "${aws_acm_certificate.acm_cert.arn}"    
      #"alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01" #Optional (Picks default if not used)    
      # SSL Redirect Setting
      "alb.ingress.kubernetes.io/ssl-redirect" = 443
      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfingress-groups-demo102.stacksimplify.com"
      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name" = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 20
    }    
  }

  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class        
    rule {
      http {
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

## Step-12: c12-kubernetes-app3-ingress-service.tf
- **Project Folder:** 05-ingress-groups-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress_app3" {
  metadata {
    name = "app3-ingress"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-groups-demo"
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
      "alb.ingress.kubernetes.io/certificate-arn" =  "${aws_acm_certificate.acm_cert.arn}"    
      #"alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01" #Optional (Picks default if not used)    
      # SSL Redirect Setting
      "alb.ingress.kubernetes.io/ssl-redirect" = 443
      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfingress-groups-demo102.stacksimplify.com"
      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name" = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 30
    }    
  }

  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class        
    # Default Backend    
    default_backend {
      service {
        name = kubernetes_service_v1.myapp3_np_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
  }
}
```


## Step-13: Execute Terraform Commands
```t
# Change Directory 
cd 05-ingress-groups-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-14: Verify Ingress Service
```t
# Verify Ingress Resource
kubectl get ingress

# Verify Apps
kubectl get deploy
kubectl get pods

# Verify NodePort Services
kubectl get svc
```

## Step-15: Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```

## Step-16: Verify Route53
- Go to Services -> Route53
- You should see **Record Set** added for 
  - tfingress-groups-demo101.stacksimplify.com


## Step-17: Access Application using newly registered DNS Name
- Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup tfingress-groups-demo102.stacksimplify.com
```
## Step-18: Access Application 
```t
# Access App1
http://tfingress-groups-demo102.stacksimplify.com/app1/index.html

# Access App2
http://tfingress-groups-demo102.stacksimplify.com/app2/index.html

# Access Default App (App3)
http://tfingress-groups-demo102.stacksimplify.com
```


## Step-19: Clean-Up Ingress
```t
# Change Directory 
cd 05-ingress-groups-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-20: Don't Clean-Up EKS Cluster, LBC Controller and ExternalDNS
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



