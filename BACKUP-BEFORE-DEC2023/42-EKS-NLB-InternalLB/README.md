---
title: AWS EKS Kubernetes Internal NLB with Terraform
description: Learn to create Internal AWS Network Load Balancer with Kubernetes and Terraform
---

## Step-01: Introduction
- Create Internal NLB
- Update NLB Service k8s manifest and terraform manifest with `aws-load-balancer-scheme` Annotation as `internal`
- Deploy curl pod
- Connect to curl pod and access Internal NLB endpoint using `curl command`.


## Step-02: Review LB Scheme Annotation
- **File Name:** `04-kube-manifests-nlb-internal\02-LBC-NLB-LoadBalancer-Service.yml`
```yaml
    # Access Control
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
```

## Step-03: Deploy all kube-manifests
```t
# Deploy kube-manifests
kubectl apply -f 04-kube-manifests-nlb-internal/

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
Observation:  Should see two listeners Port 80 

Go to Services -> EC2 -> Load Balancing -> Target Groups
1. Verify Registered targets
2. Verify Health Check path
```

## Step-04: Deploy curl pod and test Internal NLB
```t
# Deploy curl-pod
kubectl apply -f 05-kube-manifests-curl/

# Will open up a terminal session into the container
kubectl exec -it curl-pod -- sh

# We can now curl external addresses or internal services:
curl http://google.com/
curl <INTERNAL-NETWORK-LB-DNS>

# Internal Network LB Curl Test
curl lbc-network-lb-internal-demo-7031ade4ca457080.elb.us-east-1.amazonaws.com
```


## Step-05: Clean-Up
```t
# Delete or Undeploy kube-manifests
kubectl delete -f 04-kube-manifests-nlb-internal/
kubectl delete -f 05-kube-manifests-curl/

# Verify if NLB deleted 
In AWS Mgmt Console, 
Go to Services -> EC2 -> Load Balancing -> Load Balancers
```

## Step-06: Review Terraform Manifests
- **Folder Name:** 06-nlb-internal-terraform-manifests
1. c1-versions.tf
2. c2-remote-state-datasource.tf
3. c3-providers.tf
4. c4-kubernetes-app3-deployment.tf

## Step-07: c5-kubernetes-app3-nlb-service.tf
- **Folder Name:** 06-nlb-internal-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Network Load Balancer Service)
resource "kubernetes_service_v1" "myapp3_nlb_service" {
  metadata {
    name = "lbc-network-lb-internal"
    annotations = {
      # Traffic Routing
      "service.beta.kubernetes.io/aws-load-balancer-name" = "lbc-network-lb-internal"
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
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal" # specifies whether the NLB will be internet-facing or internal
      # The VPC CIDR will be used if service.beta.kubernetes.io/aws-load-balancer-scheme is internal
      #"service.beta.kubernetes.io/load-balancer-source-ranges" = "0.0.0.0/0"  # specifies the CIDRs that are allowed to access the NLB.
      
      # AWS Resource Tags
      "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Environment=dev, Team=test"
    }        
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app
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

## Step-08: c6-kubernetes-curl-pod-for-testing-InternalLB.tf
- **Folder Name:** 06-nlb-internal-terraform-manifests
```t
# Kubernetes Curl Pod for Internal LB Testing
resource "kubernetes_pod_v1" "curl_pod" {
  metadata {
    name = "curl-pod"
  }

  spec {
    container {
      image = "curlimages/curl"
      name  = "curl"
      command = [ "sleep", "600" ]
    }
  }
}
```



## Step-09: Execute Terraform Commands
```t
# Change Directory 
cd 06-nlb-internal-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-10: Verify NLB Service
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


# Will open up a terminal session into the container
kubectl exec -it curl-pod -- sh

# We can now curl external addresses or internal services:
curl http://google.com/
curl <INTERNAL-NETWORK-LB-DNS>

# Internal Network LB Curl Test
curl lbc-network-lb-internal-demo-7031ade4ca457080.elb.us-east-1.amazonaws.com
Observation: 
1. This should fail. 
2. Network LB DNS resolves to 10.x.x.x subnet (VPC Subnet ) but we are inside EKS Cluster, inside a curl-pod, so lets use this Kubernetes Service Cluster-IP once.

# Internal Network LB Curl Test
curl <CLUSTER-IP-OF-lbc-network-lb-internal>
curl 172.20.165.166
Observation: It should work
```

## Step-11: Test using Bastion Host inside VPC with NLB DNS Name
```t
# Start Bastion Host
Go to Services -> EC2 -> Instances -> hr-dev-BastionHost -> Instance State -> Start Instance

# Connect to Bastion Host
ssh -i <PRIVATE_KEY> ec2-user@<BASTION-HOST-PublicIP>
ssh -i ../01-ekscluster-terraform-manifests/private-key/eks-terraform-key.pem ec2-user@54.90.160.218

# NSLOOKUP Internal Network LB DNS
nslookup lbc-network-lb-internal-d34ab3da5f17aea1.elb.us-east-1.amazonaws.com

# Internal Network LB Curl Test
curl lbc-network-lb-internal-d34ab3da5f17aea1.elb.us-east-1.amazonaws.com
Observation: Should work

## Sample Output
Kalyans-MacBook-Pro:06-nlb-internal-terraform-manifests kdaida$ ssh -i ../01-ekscluster-terraform-manifests/private-key/eks-terraform-key.pem ec2-user@54.90.160.218
Last login: Tue May 17 01:14:58 2022 from 124.123.191.44

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
4 package(s) needed for security, out of 4 available
Run "sudo yum update" to apply all updates.
-bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
[ec2-user@ip-10-0-101-207 ~]$ sudo su -
[root@ip-10-0-101-207 ~]# nslookup lbc-network-lb-internal-d34ab3da5f17aea1.elb.us-east-1.amazonaws.com
Server:		10.0.0.2
Address:	10.0.0.2#53

Non-authoritative answer:
Name:	lbc-network-lb-internal-d34ab3da5f17aea1.elb.us-east-1.amazonaws.com
Address: 10.0.1.37

[root@ip-10-0-101-207 ~]# curl lbc-network-lb-internal-d34ab3da5f17aea1.elb.us-east-1.amazonaws.com
<!DOCTYPE html>
<html>
   <body style="background-color:lightgoldenrodyellow;">
      <h1>Welcome to Stack Simplify</h1>
      <p>Kubernetes Fundamentals Demo</p>
      <p>Application Version: V1</p>
   </body>
</html>[root@ip-10-0-101-207 ~]# exit
logout
[ec2-user@ip-10-0-101-207 ~]$ exit
logout
Connection to 54.90.160.218 closed.
Kalyans-MacBook-Pro:06-nlb-internal-terraform-manifests kdaida$
```

## Step-12: Clean-Up
```t
# Change Directory 
cd 06-nlb-internal-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-13: Don't Clean-Up EKS Cluster, LBC Controller and ExternalDNS
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



