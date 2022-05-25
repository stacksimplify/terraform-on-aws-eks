---
title: Kubernetes Resources using Terraform 
description: Create Kubernetes Resources using Terraform Kubernetes Provider
---

## Step-01: Introduction
1. [Kubernetes Terraform Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
2. Kubernetes Resources using Terraform
   1. Kubernetes Deployment Resource
   2. Kubernetes LoadBalancer Service Resource
   3. Kubernetes NodePort Service Resource
3. [Terraform Remote State Datasource Concept](https://www.terraform.io/docs/language/state/remote-state-data.html)
4. Terraform State sharing across multiple projects which uses local backend 
5. [Terraform Backends Concept](https://www.terraform.io/docs/language/settings/backends/index.html)

## Step-02: Review the EKS Cluster Resouces
- **Folder:** `08-AWS-EKS-Cluster-Basics/01-ekscluster-terraform-manifests`
- No changes from previous section

## Step-03: c1-versions.tf
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- **Folder:** 02-k8sresources-terraform-manifests
```t
# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.70"
     }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7"
    }     
  }
}
```
## Step-04: c2-remote-state-datasource.tf
- [Terraform Remote State Datasource](https://www.terraform.io/language/state/remote-state-data)
- **Folder:** 02-k8sresources-terraform-manifests
- **Important Note:** We will use the Terraform State file `terraform.tfstate` file from ekscluster Terraform project to get the EKS Resources information
```t
# Terraform Remote State Datasource
data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../../08-AWS-EKS-Cluster-Basics/01-ekscluster-terraform-manifests/terraform.tfstate"
  }
}
```
## Step-05: c3-providers.tf
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- **Folder:** 02-k8sresources-terraform-manifests
- Define AWS Provider and Kubernetes Provider
- Also define the Terraform Datasources required to access required data. 
```t
# Terraform AWS Provider Block
provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

# Terraform Kubernetes Provider
provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```
## Step-06: c4-kubernetes-deployment.tf
- **Review** [Terraform Kubernetes Versioned Resource Names](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/versioned-resources)
- [Terraform Kubernetes Deployment Manifest](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1)
- **Folder:** 02-k8sresources-terraform-manifests
```t
# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp1" {
  metadata {
    name = "myapp1-deployment"
    labels = {
      app = "myapp1"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "myapp1"
      }      
    }
    template {
      metadata {
        labels = {
          app = "myapp1"
        }
      }
      spec {
        container {
          image = "stacksimplify/kubenginx:1.0.0"
          name  = "myapp1-container"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}
```
## Step-07: c5-kubernetes-loadbalancer-service.tf
- **Folder:** 02-k8sresources-terraform-manifests
- [Terraform Kubernetes Service Manifest](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1)
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_service_v1" "lb_service" {
  metadata {
    name = "myapp1-lb-service-clb"
  }
  spec {
    selector = {
      #app = kubernetes_deployment_v1.myapp1.spec.0.template.0.metadata[0].labels.app
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
```
## Step-08: c6-kubernetes-nodeport-service.tf
- **Folder:** 02-k8sresources-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "np_service" {
  metadata {
    name = "myapp1-nodeport-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app      
    }
    port {
      port        = 80
      target_port = 80
      node_port = 31280
    }

    type = "NodePort"
  }
}
```
## Step-09: c7-kubernetes-loadbalancer-service-nlb.tf
```t
# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_service_v1" "lb_service_nlb" {
  metadata {
    name = "myapp1-lb-service-nlb"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"    # To create Network Load Balancer
    }    
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app      
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
```
## Step-10: Create Kubernetes Resources: Execute Terraform Commands
```t
# Change Directroy
cd 11-Kubernetes-Resources-via-Terraform/02-k8sresources-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-11: Verify Kubernetes Resources
```t
# List Nodes
kubectl get nodes -o wide

# List Pods
kubectl get pods -o wide
Observation: 
1. Both app pod should be in Public Node Group 

# List Services
kubectl get svc
kubectl get svc -o wide
Observation:
1. We should see both Load Balancer Service and NodePort service created

# Access Sample Application on Browser
http://<CLB-DNS-NAME>
http://<NLB-DNS-NAME>
http://abb2f2b480148414f824ed3cd843bdf0-805914492.us-east-1.elb.amazonaws.com
```

## Step-12: Verify Kubernetes Resources via AWS Management console
1. Go to Services -> EC2 -> Load Balancing -> Load Balancers
2. Verify Tabs
   - Description: Make a note of LB DNS Name
   - Instances
   - Health Checks
   - Listeners
   - Monitoring


## Step-13: Node Port Service Port - Update/Verify Node Security Group
- **Important Note:** This is not a recommended option to update the Node Security group to open ports to internet, but just for learning and testing we are doing this. 
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Add an additional Inbound Rule
   - **Type:** Custom TCP
   - **Protocol:** TCP
   - **Port range:** 31280
   - **Source:** Anywhere (0.0.0.0/0)
   - **Description:** NodePort Rule
- Click on **Save rules**

## Step-14: Verify by accessing the Sample Application using NodePort Service
```t
# List Nodes
kubectl get nodes -o wide
Observation: Make a note of the Node External IP

# List Services
kubectl get svc
Observation: Make a note of the NodePort service port "myapp1-nodeport-service" which looks as "80:31280/TCP"

# Access the Sample Application in Browser
http://<EXTERNAL-IP-OF-NODE>:<NODE-PORT>
http://54.165.248.51:31280
```

## Step-15: Remove Inbound Rule added 
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Remove the NodePort Rule which we added.

## Step-16: Clean-Up
```t
# Delete Kubernetes  Resources
cd 02-k8sresources-terraform-manifests
terraform apply -destroy -auto-approve
rm -rf .terraform* terraform.tfstate*

# Delete EKS Cluster
cd 08-AWS-EKS-Cluster-Basics/01-ekscluster-terraform-manifests/
terraform apply -destroy -auto-approve
rm -rf .terraform* terraform.tfstate*
```