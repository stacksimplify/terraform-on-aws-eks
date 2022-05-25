---
title: AWS EKS Ingress SSL Redirect with Terraform
description: Learn AWS Load Balancer Controller - Ingress SSL and SSL Redirect automate with Terraform
---

## Step-01: Introduction
- We are going to register a new DNS in AWS Route53
- We are going to create a SSL certificate 
- Add Annotations related to SSL Certificate in Ingress manifest
- Deploy the kube-manifests, test and Clean-Up
- Automate the same usecase using Terraform
- Deploy Terraform manifests for this usecase, test and clean-up

## Step-02: Pre-requisite - Register a Domain in Route53 (if not exists)
- Goto Services -> Route53 -> Registered Domains
- Click on **Register Domain**
- Provide **desired domain: somedomain.com** and click on **check** (In my case its going to be `stacksimplify.com`)
- Click on **Add to cart** and click on **Continue**
- Provide your **Contact Details** and click on **Continue**
- Enable Automatic Renewal
- Accept **Terms and Conditions**
- Click on **Complete Order**

## Step-03: Create a SSL Certificate in Certificate Manager
- Pre-requisite: You should have a registered domain in Route53 
- Go to Services -> Certificate Manager -> Create a Certificate
- Click on **Request a Certificate**
  - Choose the type of certificate for ACM to provide: Request a public certificate
  - Add domain names: *.yourdomain.com (in my case it is going to be `*.stacksimplify.com`)
  - Select a Validation Method: **DNS Validation**
  - Click on **Confirm & Request**    
- **Validation**
  - Click on **Create record in Route 53**  
- Wait for 5 to 10 minutes and check the **Validation Status**  

## Step-04: Add annotations related to SSL
- **04-ALB-Ingress-SSL.yml**
```yaml
    ## SSL Settings
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:180789647333:certificate/632a3ff6-3f6d-464c-9121-b9d97481a76b
    #alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-1-2017-01 #Optional (Picks default if not used)   

    # SSL Redirect Setting
    alb.ingress.kubernetes.io/ssl-redirect: '443'  
```
## Step-05: Deploy all manifests and test
### Deploy and Verify
```t
# Change Directory 
cd 29-EKS-Ingress-SSL-SSLRedirect

# Deploy kube-manifests
kubectl apply -f 03-kube-manifests-Ingress-SSL/

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

## Step-06: Add DNS in Route53   
- Go to **Services -> Route 53**
- Go to **Hosted Zones**
  - Click on **yourdomain.com** (in my case stacksimplify.com)
- Create a **Record Set**
  - **Name:** ssldemo101.stacksimplify.com
  - **Alias:** yes
  - **Alias Target:** Copy our ALB DNS Name here (Sample: ssl-ingress-551932098.us-east-1.elb.amazonaws.com)
  - Click on **Create**
  
## Step-07: Access Application using newly registered DNS Name
- **Access Application**
- **Important Note:** Instead of `stacksimplify.com` you need to replace with your registered Route53 domain (Refer pre-requisite Step-02)
```t
# HTTP URLs (Should redirect to HTTPS URL)
http://ssldemo101.stacksimplify.com/app1/index.html
http://ssldemo101.stacksimplify.com/app2/index.html
http://ssldemo101.stacksimplify.com/

# HTTPS URLs 
https://ssldemo101.stacksimplify.com/app1/index.html
https://ssldemo101.stacksimplify.com/app2/index.html
https://ssldemo101.stacksimplify.com/
```

## Step-08: Clean Up
```t
# Delete Manifests
kubectl delete -f kube-manifests/

## Delete Route53 Record Set
- Delete Route53 Record we created (ssldemo101.stacksimplify.com)
```

## Step-09: Review Terraform Manifests 
- **Project Folder:** 04-ingress-ssl-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app1-deployment.tf
5. c5-kubernetes-app2-deployment.tf
6. c6-kubernetes-app3-deployment.tf
7. c7-kubernetes-app1-nodeport-service.tf
8. c8-kubernetes-app2-nodeport-service.tf
9. c9-kubernetes-app3-nodeport-service.tf

## Step-10: c11-acm-certificate.tf
```t
# Resource: ACM Certificate
resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "*.stacksimplify.com"
  validation_method = "DNS"

  tags = {
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs
output "acm_certificate_id" {
  value = aws_acm_certificate.acm_cert.id 
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.acm_cert.arn
}

output "acm_certificate_status" {
  value = aws_acm_certificate.acm_cert.status
}
```

## Step-11: c10-kubernetes-ingress-service.tf
- [Terraform jsonencode function](https://www.terraform.io/language/functions/jsonencode)
- Two changes 
- **SSL Port 443**
```t
      # Option-1: Using Terraform jsonencode Function
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTPS" = 443}, {"HTTP" = 80}])
```
- **ACM Certificate ARN created in c11-acm-certificate.tf**
```t
      "alb.ingress.kubernetes.io/certificate-arn" =  "${aws_acm_certificate.acm_cert.arn}"
```
- **Full Ingress Service Manifest**
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress-ssl-demo"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-ssl-demo"
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

## Step-12: Execute Terraform Commands
```t
# Change Directory 
cd 04-ingress-ssl-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-13: Verify Ingress Service
```t
# Verify Ingress Resource
kubectl get ingress

# Verify Apps
kubectl get deploy
kubectl get pods

# Verify NodePort Services
kubectl get svc
```

## Step-14: Add DNS in Route53   
- Go to **Services -> Route 53**
- Go to **Hosted Zones**
  - Click on **yourdomain.com** (in my case stacksimplify.com)
- Create a **Record Set**
  - **Name:** ssldemo102.stacksimplify.com
  - **Alias:** yes
  - **Alias Target:** Copy our ALB DNS Name here (Sample: ssl-ingress-551932098.us-east-1.elb.amazonaws.com)
  - Click on **Create**
  
## Step-15: Access Application using newly registered DNS Name
- **Access Application**
- **Important Note:** Instead of `stacksimplify.com` you need to replace with your registered Route53 domain (Refer pre-requisite Step-02)
```t
# HTTP URLs (Should redirect to HTTPS URL)
http://ssldemo102.stacksimplify.com/app1/index.html
http://ssldemo102.stacksimplify.com/app2/index.html
http://ssldemo102.stacksimplify.com/

# HTTPS URLs 
https://ssldemo102.stacksimplify.com/app1/index.html
https://ssldemo102.stacksimplify.com/app2/index.html
https://ssldemo102.stacksimplify.com/
```


## Step-16: Clean-Up Ingress
```t
# Change Directory 
cd 04-ingress-ssl-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*

## Delete Route53 Record Set
- Delete Route53 Record we created (ssldemo101.stacksimplify.com)
```

## Step-17: Don't Clean-Up LBC Controller & EKS Cluster
- Dont destroy the Terraform Projects in below two folders
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-lbc-install-terraform-manifests
- We are going to use them for all upcoming Usecases.
- If you want to destroy all things today and and recreate them tomorrow here is the order for destroying resources
- First Destroy LBC Terraform Project related resources. This will uninstall LBC Controller
- Finally Destroy  EKS Cluster Project related resources. 
```t
## Destroy  LBC
# Change Directroy
cd 02-lbc-install-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve

## Destroy EKS Cluster
# Change Directroy
cd 01-ekscluster-terraform-manifests

# Terraform Destroy
terraform init
terraform apply -destroy -auto-approve
```


## Annotation Reference
- [AWS Load Balancer Controller Annotation Reference](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/)



