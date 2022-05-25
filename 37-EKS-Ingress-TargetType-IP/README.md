---
title: AWS EKS Ingress Target Type IP Automate with Terraform
description: Learn AWS EKS Ingress Target Type IP and Automate it with Terraform
---

## Step-01: Introduction
- `alb.ingress.kubernetes.io/target-type` specifies how to route traffic to pods. 
- You can choose between `instance` and `ip`
- **Instance Mode:** `instance mode` will route traffic to all ec2 instances within cluster on NodePort opened for your service.
- **IP Mode:** `ip mode` is required for sticky sessions to work with Application Load Balancers.


## Step-02: Ingress Manifest - Add target-type
- **File Name:** 04-ALB-Ingress-target-type-ip.yml
```yaml
    # Target Type: IP
    alb.ingress.kubernetes.io/target-type: ip   
```

## Step-03: Deploy all Application Kubernetes Manifests and Verify
```t
# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-ingress-TargetType-IP

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
- **PRIMARILY VERIFY - TARGET GROUPS which contain thePOD IPs instead of WORKER NODE IP with NODE PORTS**
```t
# List Pods and their IPs
kubectl get pods -o wide
```

### Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```
### Verify Route53
- Go to Services -> Route53
- You should see **Record Sets** added for 
  - target-type-ip-501.stacksimplify.com 


## Step-04: Access Application using newly registered DNS Name
### Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup target-type-ip-501.stacksimplify.com 
```
### Access Application using DNS domain
```t
# Access App1
http://target-type-ip-501.stacksimplify.com /app1/index.html

# Access App2
http://target-type-ip-501.stacksimplify.com /app2/index.html

# Access Default App (App3)
http://target-type-ip-501.stacksimplify.com 
```

## Step-05: Clean Up
```t
# Delete Manifests
kubectl delete -f 04-kube-manifests-ingress-TargetType-IP

## Verify Route53 Record Set to ensure our DNS records got deleted
- Go to Route53 -> Hosted Zones -> Records 
- The below records should be deleted automatically
  - target-type-ip-501.stacksimplify.com 
```



## Step-06: Review Terraform Manifests 
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
10. c11-acm-certificate.tf


## Step-07: c10-kubernetes-ingress-service.tf
- **Project Folder:** 05-ingress-TargetType-IP-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress-target-type-ip-demo"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "target-type-ip-ingress"
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
      "external-dns.alpha.kubernetes.io/hostname" = "tftarget-type-ip-501.stacksimplify.com"
      # Target Type: IP (Defaults to Instance if not specified)
      "alb.ingress.kubernetes.io/target-type" = "ip"
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

## Step-08: Execute Terraform Commands
```t
# Change Directory 
cd 05-ingress-TargetType-IP-terraform-manifests

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
- You should see **Record Set** added for 
  - tftarget-type-ip-501.stacksimplify.com


## Step-12: Access Application using newly registered DNS Name
- Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup tftarget-type-ip-501.stacksimplify.com
```
## Step-13: Access Application 
```t
# Access App1
http://tftarget-type-ip-501.stacksimplify.com/app1/index.html

# Access App2
http://tftarget-type-ip-501.stacksimplify.com/app2/index.html

# Access Default App (App3)
http://tftarget-type-ip-501.stacksimplify.com
```
## Step-14: Clean-Up Ingress
```t
# Change Directory 
cd 05-ingress-TargetType-IP-terraform-manifests

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



