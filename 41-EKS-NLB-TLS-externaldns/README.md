---
title: AWS EKS kubernetes NLB TLS External DNS with Terraform
description: Learn to use AWS NLB TLS and External DNS with AWS Load Balancer Controller and Terraform
---

## Step-01: Introduction
- Understand about the 4 TLS Annotations for Network Load Balancers
- aws-load-balancer-ssl-cert
- aws-load-balancer-ssl-ports
- aws-load-balancer-ssl-negotiation-policy
- aws-load-balancer-ssl-negotiation-policy
- Implement External DNS Annotation in NLB Kubernetes Service Manifest

## Step-02: Review TLS Annotations
- **File Name:** `04-kube-manifests-nlb-tls-externaldns\02-LBC-NLB-LoadBalancer-Service.yml`
- **Security Policies:** https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies
```yaml
    # TLS
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-east-1:180789647333:certificate/d86de939-8ffd-410f-adce-0ce1f5be6e0d
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: 443, # Specify this annotation if you need both TLS and non-TLS listeners on the same load balancer
    service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: ELBSecurityPolicy-TLS13-1-2-2021-06
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp 
```


## Step-03: Review External DNS Annotations
- **File Name:** `04-kube-manifests-nlb-tls-externaldns\02-LBC-NLB-LoadBalancer-Service.yml`
```yaml
    # External DNS - For creating a Record Set in Route53
    external-dns.alpha.kubernetes.io/hostname: nlbdns101.stacksimplify.com
```

## Step-03: Deploy all kube-manifests
```t
# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-nlb-tls-externaldns/

# Verify Pods
kubectl get pods

# Verify Services
kubectl get svc
Observation: 
1. Verify the network lb DNS name

# Verify AWS Load Balancer Controller pod logs
kubectl -n kube-system get pods
kubectl -n kube-system logs -f <aws-load-balancer-controller-POD-NAME>

# Verify using AWS Mgmt Console
Go to Services -> EC2 -> Load Balancing -> Load Balancers
1. Verify Description Tab - DNS Name matching output of "kubectl get svc" External IP
2. Verify Listeners Tab
Observation:  Should see two listeners Port 80 and 443

Go to Services -> EC2 -> Load Balancing -> Target Groups
1. Verify Registered targets
2. Verify Health Check path
Observation: Should see two target groups. 1 Target group for 1 listener

# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')

# Perform nslookup Test
nslookup nlbdns101.stacksimplify.com

# Access Application
# Test HTTP URL
http://nlbdns101.stacksimplify.com

# Test HTTPS URL
https://nlbdns101.stacksimplify.com
```

## Step-04: Clean-Up
```t
# Delete or Undeploy kube-manifests
kubectl delete -f 04-kube-manifests-nlb-tls-externaldns/

# Verify if NLB deleted 
In AWS Mgmt Console, 
Go to Services -> EC2 -> Load Balancing -> Load Balancers
```

## Step-05: Review Terraform Manifests
- **Folder Name:** 05-nlb-tls-extdns-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app3-deployment.tf
5. c6-acm-certificate.tf

## Step-06: c5-kubernetes-app3-nlb-service.tf
- **Folder Name:** 05-nlb-tls-extdns-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Network Load Balancer Service)
resource "kubernetes_service_v1" "myapp3_nlb_service" {
  metadata {
    name = "extdns-tls-lbc-network-lb"
    annotations = {
      # Traffic Routing
      "service.beta.kubernetes.io/aws-load-balancer-name" = "extdns-tls-lbc-network-lb"
      "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance" # specifies the target type to configure for NLB. You can choose between instance and ip
      #service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-xxxx, mySubnet ## Subnets are auto-discovered if this annotation is not specified, see Subnet Discovery for further details.
      
      # Health Check Settings
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "http"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port" = "traffic-port"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path" = "/index.html"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold" = 3
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold" = 3
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval" = 10 # The controller currently ignores the timeout configuration due to the limitations on the AWS NLB. The default timeout for TCP is 10s and HTTP is 6s.

      # Access Control
      "service.beta.kubernetes.io/load-balancer-source-ranges" = "0.0.0.0/0"  # specifies the CIDRs that are allowed to access the NLB.
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing" # specifies whether the NLB will be internet-facing or internal

      # AWS Resource Tags
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Environment=dev, Team=test"

      # TLS
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = "${aws_acm_certificate.acm_cert.arn}"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "443" # Specify this annotation if you need both TLS and non-TLS listeners on the same load balancer
      "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"

      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "tfnlbdns101.stacksimplify.com"
    }        
  }
  spec {
    selector = {
      #app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app  # Both representations are same "spec.0." or "spec[0]."
      app = kubernetes_deployment_v1.myapp3.spec[0].selector[0].match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    port {
      name        = "https"
      port        = 443
      target_port = 80
    }    
    type = "LoadBalancer"
  }
}
```


## Step-07: Execute Terraform Commands
```t
# Change Directory 
cd 05-nlb-tls-extdns-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-08: Verify NLB Service
```t
# Verify Pods
kubectl get pods

# Verify Services
kubectl get svc
Observation: 
1. Verify the network lb DNS name

# Verify AWS Load Balancer Controller pod logs
kubectl -n kube-system get pods
kubectl -n kube-system logs -f <aws-load-balancer-controller-POD-NAME>

# Verify using AWS Mgmt Console
Go to Services -> EC2 -> Load Balancing -> Load Balancers
1. Verify Description Tab - DNS Name matching output of "kubectl get svc" External IP
2. Verify Listeners Tab

Go to Services -> EC2 -> Load Balancing -> Target Groups
1. Verify Registered targets
2. Verify Health Check path


# Verify External DNS logs
kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')

# Perform nslookup Test
nslookup nlbdns101.stacksimplify.com

# Access Application
# Test HTTP URL
http://nlbdns101.stacksimplify.com

# Test HTTPS URL
https://nlbdns101.stacksimplify.com
```

## Step-09: Clean-Up
```t
# Change Directory 
cd 05-nlb-tls-extdns-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-10: Don't Clean-Up EKS Cluster, LBC Controller and ExternalDNS
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
- [Network Load Balancer](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)
- [NLB Service](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/nlb/)
- [NLB Service Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/)

