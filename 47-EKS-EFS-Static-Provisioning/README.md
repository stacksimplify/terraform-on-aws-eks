---
title: AWS EKS EFS Static Provisioning with Terraform
description: Learn to Automate AWS EKS Kubernetes EFS Static Provisioning with Terraform
---

## Step-01: Introduction
- Implement and Test EFS Static Provisioning Usecase

## Step-02: Project-03: Review Terraform Manifests
- **Project Folder:** 03-efs-static-prov-terraform-manifests
1. c1-versions.tf
  - Create DynamoDB Table `dev-efs-sampleapp-demo`
2. c2-remote-state-datasource.tf
```t
# Terraform Remote State Datasource - Remote Backend AWS S3
# EKS Cluster Project
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-eks"
    key    = "dev/eks-cluster/terraform.tfstate"
    region = "us-east-1" 
  }
}

# EFS CSI Project
data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-eks"
    key    = "dev/efs-csi/terraform.tfstate"
    region = "us-east-1" 
  }
}
```
3. c3-providers.tf

## Step-02: c4-01-efs-resource.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Security Group - Allow Inbound NFS Traffic from EKS VPC CIDR to EFS File System
resource "aws_security_group" "efs_allow_access" {
  name        = "efs-allow-nfs-from-eks-vpc"
  description = "Allow Inbound NFS Traffic from VPC CIDR"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    description      = "Allow Inbound NFS Traffic from EKS VPC CIDR to EFS File System"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [data.terraform_remote_state.eks.outputs.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nfs_from_eks_vpc"
  }
}


# Resource: EFS File System
resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "efs-demo"
  tags = {
    Name = "efs-demo"
  }
}

# Resource: EFS Mount Target
resource "aws_efs_mount_target" "efs_mount_target" {
  #for_each = toset(module.vpc.private_subnets)
  count = 2
  file_system_id = aws_efs_file_system.efs_file_system.id
  subnet_id      = data.terraform_remote_state.eks.outputs.private_subnets[count.index]
  security_groups = [ aws_security_group.efs_allow_access.id ]
}


# EFS File System ID
output "efs_file_system_id" {
  description = "EFS File System ID"
  value = aws_efs_file_system.efs_file_system.id 
}

output "efs_file_system_dns_name" {
  description = "EFS File System DNS Name"
  value = aws_efs_file_system.efs_file_system.dns_name
}

# EFS Mounts Info
output "efs_mount_target_id" {
  description = "EFS File System Mount Target ID"
  value = aws_efs_mount_target.efs_mount_target[*].id 
}

output "efs_mount_target_dns_name" {
  description = "EFS File System Mount Target DNS Name"
  value = aws_efs_mount_target.efs_mount_target[*].mount_target_dns_name 
}

output "efs_mount_target_availability_zone_name" {
  description = "EFS File System Mount Target availability_zone_name"
  value = aws_efs_mount_target.efs_mount_target[*].availability_zone_name 
}
```
## Step-04: c4-02-storage-class.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Kubernetes Storage Class
resource "kubernetes_storage_class_v1" "efs_sc" {  
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"  
}
```
## Step-05: c4-03-persistent-volume-claim.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Persistent Volume Claim
resource "kubernetes_persistent_volume_claim_v1" "efs_pvc" {
  metadata {
    name = "efs-claim"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class_v1.efs_sc.metadata[0].name 
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
} 
```
## Step-06: c4-04-persistent-volume.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Kubernetes Persistent Volume
resource "kubernetes_persistent_volume" "efs_pv" {
  metadata {
    name = "efs-pv" 
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class_v1.efs_sc.metadata[0].name    
    persistent_volume_source {
      csi {
      driver = "efs.csi.aws.com"
      volume_handle = aws_efs_file_system.efs_file_system.id
      }
    }
  } 
} 
```

## Step-07: c5-write-to-efs-pod.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Kubernetes Pod - Write to EFS Pod
resource "kubernetes_pod_v1" "efs_write_app_pod" {
  depends_on = [ aws_efs_mount_target.efs_mount_target]    
  metadata {
    name = "efs-write-app"
  }
  spec {
    container {
      name  = "efs-write-app"
      image = "busybox"
      command = ["/bin/sh"]
      args = ["-c", "while true; do echo EFS Kubernetes Static Provisioning Test $(date -u) >> /data/efs-static.txt; sleep 5; done"]
      volume_mount {
        name = "persistent-storage"
        mount_path = "/data"
      }
  }
  volume {
    name = "persistent-storage"
    persistent_volume_claim {
      claim_name = kubernetes_persistent_volume_claim_v1.efs_pvc.metadata[0].name 
    } 
  }
}
} 
```
## Step-08: c6-01-myapp1-deployment.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: UserMgmt WebApp Kubernetes Deployment
resource "kubernetes_deployment_v1" "myapp1" {
  depends_on = [ aws_efs_mount_target.efs_mount_target]    
  metadata {
    name = "myapp1"
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
        name = "myapp1-pod"
        labels = {
          app = "myapp1"
        }
      }
      spec {
        container {
          name  = "myapp1-container"
          image = "stacksimplify/kubenginx:1.0.0"
          port {
            container_port = 80
          }
          volume_mount {
            name = "persistent-storage"
            mount_path = "/usr/share/nginx/html/efs"
          }
        }
        volume {          
          name = "persistent-storage"
          persistent_volume_claim {
          claim_name = kubernetes_persistent_volume_claim_v1.efs_pvc.metadata[0].name 
        }
      }
    }
  }
}
}
```
## Step-09: c6-02-myapp1-loadbalancer-service.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Kubernetes Service Manifest (Type: Load Balancer - Classic)
resource "kubernetes_service_v1" "lb_service" {
  metadata {
    name = "myapp1-clb-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec[0].selector[0].match_labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
```
## Step-10: c6-03-myapp1-network-loadbalancer-service.tf
- **Project Folder:** 03-efs-static-prov-terraform-manifests
```t
# Resource: Kubernetes Service Manifest (Type: Load Balancer - Network)
resource "kubernetes_service_v1" "network_lb_service" {
  metadata {
    name = "myapp1-network-lb-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"    # To create Network Load Balancer
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec[0].selector[0].match_labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
```
## Step-11: Project-03: Execute Terraform Commands
```t
# Change Directory 
cd 03-efs-static-prov-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-12: Verify Kubernetes Resources
```t
# Verify Storage Class
kubectl get sc

# Verify PVC (Persistent Volume Claim)
kubectl get pvc

# Verify PV (Persistent Volume)
kubectl get pv
```


## Step-13: Verify EFS File System, Mount Targets, Network Interfaces and Security Groups
```t
# Verify EFS File System
Go to Services -> EFS -> File Systems -> efs-demo

# Verify Mount Targets
Go to Services -> EFS -> File Systems -> efs-demo -> Network Tab

# Verify Network Interfaces
Go to Services -> EC2 -> Network & Security -> Network Interfaces -> GET THE ENI ID from Mount Targets

# Security Groups
Go to Services -> EC2 -> Network & Security -> Security Groups -> hr-dev-efs-allow-nfs-from-eks-vpc
```

## Step-14: Connect to efs-write-app Kubernetes pods and Verify 
```t
# efs-write-app - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty efs-write-app  -- /bin/sh
cd /data
ls
tail -f efs-static.txt
```

## Step-15: Connect to myapp1 Kubernetes pods and Verify 
```t
# List Pods
kubectl get pods 

# myapp1 POD1 - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty myapp1-667d8656cc-2x824 -- /bin/sh
cd /usr/share/nginx/html/efs
ls
tail -f efs-static.txt

# myapp1 POD2 - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty myapp1-667d8656cc-bg8bg  -- /bin/sh
cd /usr/share/nginx/html/efs
ls
tail -f efs-static.txt
```

## Step-16: Access Application
```t
# Access Application
http://<CLB-DNS-URL>/efs/efs-static.txt
http://<NLB-DNS-URL>/efs/efs-static.txt
```

## Step-17: Clean-Up
```t
# Change Directory
cd 03-efs-static-prov-terraform-manifests

# Destroy Resources
terraform apply -destroy -auto-approve
rm -rf .terraform*
```


## Step-18: DONT Clean-Up EKS Cluster, EFS CSI Driver
- DONT Destroy the Terraform Projects in below two folders.
- We are going to use them in next section **48-EKS-EFS-Dynamic-Provisioning**
- **Terraform Project Folder:** 01-ekscluster-terraform-manifests
- **Terraform Project Folder:** 02-efs-install-terraform-manifests
- We are going to use them for all upcoming Usecases.
- Destroy Resorces Order
  - 02-efs-install-terraform-manifests
  - 01-ekscluster-terraform-manifests
```t
##############################################################
## Delete EFS CSI Driver
# Change Directory
cd 02-efs-install-terraform-manifests

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
- [AWS IAM OIDC Connect Provider](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html)
- [AWS EFS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)
- [AWS Caller Identity Datasource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)
- [HTTP Datasource](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http)
- [AWS IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [AWS IAM Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
- [AWS EFS CSI Docker Images across Regions](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html)
- [To find latestEFS CSI Driver GIT Repo](https://github.com/kubernetes-sigs/aws-efs-csi-driver/)


