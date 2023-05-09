---
title: AWS EKS Ingress and ExternalDNS with Terraform
description: Learn to update AWS Route53 records using ExternalDNS in Ingress Service on AWS EKS Cluster
---


## Step-01: Update Ingress manifest by adding External DNS Annotation
- Added annotation with two DNS Names
  - dnstest901.kubeoncloud.com
  - dnstest902.kubeoncloud.com
- Once we deploy the application, we should be able to access our Applications with both DNS Names.   
- **File Name:** 04-ALB-Ingress-SSL-Redirect-ExternalDNS.yml
```yaml
    # External DNS - For creating a Record Set in Route53
    external-dns.alpha.kubernetes.io/hostname: dnstest901.stacksimplify.com, dnstest902.stacksimplify.com
```
- In your case it is going to be, replace `yourdomain` with your domain name
  - dnstest901.yourdoamin.com
  - dnstest902.yourdoamin.com

## Step-02: Deploy all Application Kubernetes Manifests
### Deploy
```t
# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-ingress-externaldns/

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

### Verify External DNS Log
```t
# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
```
### Verify Route53
- Go to Services -> Route53
- You should see **Record Sets** added for `dnstest901.stacksimplify.com`, `dnstest902.stacksimplify.com`

## Step-04: Access Application using newly registered DNS Name
### Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup dnstest901.stacksimplify.com
nslookup dnstest902.stacksimplify.com
```
### Access Application using dnstest1 domain
```t
# HTTP URLs (Should Redirect to HTTPS)
http://dnstest901.stacksimplify.com/app1/index.html
http://dnstest901.stacksimplify.com/app2/index.html
http://dnstest901.stacksimplify.com/
```

### Access Application using dnstest2 domain
```t
# HTTP URLs (Should Redirect to HTTPS)
http://dnstest902.stacksimplify.com/app1/index.html
http://dnstest902.stacksimplify.com/app2/index.html
http://dnstest902.stacksimplify.com/
```


## Step-05: Clean Up
```t
# Delete Manifests
kubectl delete -f 04-kube-manifests-ingress-externaldns/

## Verify Route53 Record Set to ensure our DNS records got deleted
- Go to Route53 -> Hosted Zones -> Records 
- The below records should be deleted automatically
  - dnstest901.stacksimplify.com
  - dnstest902.stacksimplify.com
```

## Step-06: Review Terraform Manifests 
- **Project Folder:** 05-ingress-externaldns-terraform-manifests
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
- One Annotation Addition in Ingress Service
```t
    # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfdnstest901.stacksimplify.com, tfdnstest902.stacksimplify.com"
```

## Step-08: Execute Terraform Commands
```t
# Change Directory 
cd 05-ingress-externaldns-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Terraform Apply Refresh-Only
terraform apply -refresh-only -auto-approve
Observation: 

### SAMPLE OUTPUT ###
Changes to Outputs:
  ~ acm_certificate_status = "PENDING_VALIDATION" -> "ISSUED"
Outputs:
acm_certificate_arn = "arn:aws:acm:us-east-1:180789647333:certificate/06033cd0-3ecb-4069-8679-b54ea6678f5a"
acm_certificate_id = "arn:aws:acm:us-east-1:180789647333:certificate/06033cd0-3ecb-4069-8679-b54ea6678f5a"
acm_certificate_status = "ISSUED"
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
- You should see **Record Sets** added for `tfdnstest901.stacksimplify.com`, `tfdnstest902.stacksimplify.com`

## Step-12: Access Application using newly registered DNS Name
- Perform nslookup tests before accessing Application
- Test if our new DNS entries registered and resolving to an IP Address
```t
# nslookup commands
nslookup tfdnstest901.stacksimplify.com
nslookup tfdnstest902.stacksimplify.com
```
## Step-13: Access Application using tfdnstest1 and tfdnstest2 domains
```t
## Access Application using dnstest1 domain
# HTTP URLs (Should Redirect to HTTPS)
http://tfdnstest901.stacksimplify.com/app1/index.html
http://tfdnstest901.stacksimplify.com/app2/index.html
http://tfdnstest901.stacksimplify.com/

## Access Application using dnstest2 domain
# HTTP URLs (Should Redirect to HTTPS)
http://tfdnstest902.stacksimplify.com/app1/index.html
http://tfdnstest902.stacksimplify.com/app2/index.html
http://tfdnstest902.stacksimplify.com/
```


## Step-14: Clean-Up Ingress
```t
# Change Directory 
cd 05-ingress-externaldns-terraform-manifests

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


