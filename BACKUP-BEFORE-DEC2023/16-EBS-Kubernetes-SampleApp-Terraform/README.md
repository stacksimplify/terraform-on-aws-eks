---
title: Demo on Kubernetes Storage Class, PVC and PV with Terraform
description: Deploy UserMgmt WebApp on EKS Kubernetes with MySQL as Database using Terraform
---

## Step-00: Introduction
- Create Terraform configs for following Kubernetes Resources
   - Kubernetes Storage Class
   - Kubernetes Persistent Volume Claim
   - Kubernetes Config Map
   - Kubernetes Deployment for MySQL DB
   - Kubernetes ClusterIP Service for MySQL DB
   - Kubernetes Deployment for User Management Web Application
   - Kubernetes Load Balancer (Classic LB) for UMS Web App
   - Kubernetes Load Balancer (Network LB) for UMS Web App
   - Kubernetes Node Port Service for UMS Web App


## Pre-requisite: Verify EKS Cluster and EBS CSI Driver already Installed
### Project-01: 01-ekscluster-terraform-manifests
```t
# Change Directroy
cd 16-EBS-Kubernetes-SampleApp-Terraform/01-ekscluster-terraform-manifests

# Terraform Initialize
terraform init

# List Terraform Resources (if already EKS Cluster created as part of previous section we can see those resources)
terraform state list

# Else Run below Terraform Commands
terraform validate
terraform plan
terraform apply -auto-approve

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```
### Project-02: 02-ebs-terraform-manifests
```t
# Change Directroy
cd 16-EBS-Kubernetes-SampleApp-Terraform/02-ebs-terraform-manifests

# Terraform Initialize
terraform init

# List Terraform Resources (if already EBS CSI Driver created as part of previous section we can see those resources)
terraform state list

# Else Run below Terraform Commands
terraform validate
terraform plan
terraform apply -auto-approve

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify EBS CSI Controller and Node pods running in kube-system namespace
kubectl -n kube-system get pods
```

## Step-01: Create folder in S3 Bucket (Optional)
- This step is optional, Terraform can create this folder `dev/dev-ebs-sampleapp-demo` during `terraform apply` but to maintain consistency we create it. 
- Go to Services -> S3 -> 
- **Bucket name:** terraform-on-aws-eks
- **Create Folder**
  - **Folder Name:** dev/ebs-sampleapp-demo
  - Click on **Create Folder**  

## Step-02: Create DynamoDB Table
- Create Dynamo DB Table for EBS Sample App Demo
  - **Table Name:** dev-ebs-sampleapp-demo
  - **Partition key (Primary Key):** LockID (Type as String)
  - **Table settings:** Use default settings (checked)
  - Click on **Create**

## Step-03: c1-versions.tf
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
      version = "~> 2.7.1"
    }     
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-on-aws-eks"
    key    = "dev/dev-ebs-sampleapp-demo/terraform.tfstate"
    region = "us-east-1" 

    # For State Locking
    dynamodb_table = "dev-ebs-sampleapp-demo"    
  }    
}
```

## Step-04: c2-remote-state-datasource.tf
```t
# Terraform Remote State Datasource - Remote Backend AWS S3
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-eks"
    key    = "dev/eks-cluster/terraform.tfstate"
    region = "us-east-1" 
  }
}
```

## Step-05: c3-providers.tf
```t
# Terraform AWS Provider Block
provider "aws" {
  region = "us-east-1"
}

# Datasource: EKS Cluster
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

# Datasource: EKS Cluster Authentication
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

## Step-06: c4-01-storage-class.tf
```t
# Resource: Kubernetes Storage Class
resource "kubernetes_storage_class_v1" "ebs_sc" {  
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
}
```

## Step-07: c4-02-persistent-volume-claim.tf
```t
# Resource: Persistent Volume Claim
resource "kubernetes_persistent_volume_claim_v1" "pvc" {
  metadata {
    name = "ebs-mysql-pv-claim"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class_v1.ebs_sc.metadata.0.name 
    resources {
      requests = {
        storage = "4Gi"
      }
    }
  }
}

```

## Step-08: c4-03-UserMgmtWebApp-ConfigMap.tf
```t
 # Resource: Config Map
 resource "kubernetes_config_map_v1" "config_map" {
   metadata {
     name = "usermanagement-dbcreation-script"
   }
   data = {
    "webappdb.sql" = "${file("${path.module}/webappdb.sql")}"
   }
 } 
```
- **File Name:** `webappdb.sql`
```sql
DROP DATABASE IF EXISTS webappdb;
CREATE DATABASE webappdb; 
```

## Step-09: c4-04-mysql-deployment.tf
```t
# Resource: MySQL Kubernetes Deployment
resource "kubernetes_deployment_v1" "mysql_deployment" {
  metadata {
    name = "mysql"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mysql"
      }          
    }
    strategy {
      type = "Recreate"
    }  
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        volume {
          name = "mysql-persistent-storage"
          persistent_volume_claim {
            #claim_name = kubernetes_persistent_volume_claim_v1.pvc.metadata.0.name # THIS IS NOT GOING WORK, WE NEED TO GIVE PVC NAME DIRECTLY OR VIA VARIABLE, direct resource name reference will fail.
            claim_name = "ebs-mysql-pv-claim"
          }
        }
        volume {
          name = "usermanagement-dbcreation-script"
          config_map {
            name = kubernetes_config_map_v1.config_map.metadata.0.name 
          }
        }
        container {
          name = "mysql"
          image = "mysql:5.6"
          port {
            container_port = 3306
            name = "mysql"
          }
          env {
            name = "MYSQL_ROOT_PASSWORD"
            value = "dbpassword11"
          }
          volume_mount {
            name = "mysql-persistent-storage"
            mount_path = "/var/lib/mysql"
          }
          volume_mount {
            name = "usermanagement-dbcreation-script"
            mount_path = "/docker-entrypoint-initdb.d" #https://hub.docker.com/_/mysql Refer Initializing a fresh instance                                            
          }
        }
      }
    }      
  }
  
}
```

## Step-10: c4-05-mysql-clusterip-service.tf
```t
# Resource: MySQL Cluster IP Service
resource "kubernetes_service_v1" "mysql_clusterip_service" {
  metadata {
    name = "mysql"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.mysql_deployment.spec.0.selector.0.match_labels.app 
    }
    port {
      port        = 3306 # Service Port
      #target_port = 3306 # Container Port  # Ignored when we use cluster_ip = "None"
    }
    type = "ClusterIP"
    cluster_ip = "None" # This means we are going to use Pod IP   
  }
}
```

## Step-11: c4-06-UserMgmtWebApp-deployment.tf
```t
# Resource: UserMgmt WebApp Kubernetes Deployment
resource "kubernetes_deployment_v1" "usermgmt_webapp" {
  depends_on = [kubernetes_deployment_v1.mysql_deployment]
  metadata {
    name = "usermgmt-webapp"
    labels = {
      app = "usermgmt-webapp"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "usermgmt-webapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "usermgmt-webapp"
        }
      }
      spec {
        container {
          image = "stacksimplify/kube-usermgmt-webapp:1.0.0-MySQLDB"
          name  = "usermgmt-webapp"
          #image_pull_policy = "always"  # Defaults to Always so we can comment this
          port {
            container_port = 8080
          }
          env {
            name = "DB_HOSTNAME"
            #value = "mysql"
            value = kubernetes_service_v1.mysql_clusterip_service.metadata.0.name 
          }
          env {
            name = "DB_PORT"
            #value = "3306"
            value = kubernetes_service_v1.mysql_clusterip_service.spec.0.port.0.port
          }
          env {
            name = "DB_NAME"
            value = "webappdb"
          }
          env {
            name = "DB_USERNAME"
            value = "root"
          }
          env {
            name = "DB_PASSWORD"
            #value = "dbpassword11"
            value = kubernetes_deployment_v1.mysql_deployment.spec.0.template.0.spec.0.container.0.env.0.value
          }          
        }
      }
    }
  }
}

```

## Step-12: c4-07-UserMgmtWebApp-loadbalancer-service.tf
```t
# Resource: Kubernetes Service Manifest (Type: Load Balancer - Classic)
resource "kubernetes_service_v1" "lb_service" {
  metadata {
    name = "usermgmt-webapp-lb-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.usermgmt_webapp.spec.0.selector.0.match_labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}
```



## Step-13: c4-08-UserMgmtWebApp-network-loadbalancer-service.tf
```t
# Resource: Kubernetes Service Manifest (Type: Load Balancer - Network)
resource "kubernetes_service_v1" "network_lb_service" {
  metadata {
    name = "usermgmt-webapp-network-lb-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"    # To create Network Load Balancer
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.usermgmt_webapp.spec.0.selector.0.match_labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}
```

## Step-14: c4-09-UserMgmtWebApp-nodeport-service.tf
```t
# Resource: Kubernetes Service Manifest (Type: NodePort)
resource "kubernetes_service_v1" "nodeport_service" {
  metadata {
    name = "usermgmt-webapp-nodeport-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.usermgmt_webapp.spec.0.selector.0.match_labels.app
    }
    port {
      port        = 80
      target_port = 8080
      node_port = 31280
    }

    type = "NodePort"
  }
}
```

## Step-15: Deploy EBS Sample App: Execute Terraform Commands
```t
# Change Directory 
cd 16-EBS-Kubernetes-SampleApp-Terraform/03-terraform-manifests-UMS-WebApp

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-16: Verify Kubernetes Resources created
```t
# Verify Storage Class
kubectl get storageclass
kubectl get sc
Observation:
1. You should find two EBS Storage Classes
  - One created by default with in-tree EBS provisioner named "gp2". Future it might get deprecated
  - Recommended to use EBS CSI Provisioner for creating EBS volumes for EKS Workloads
  - That said, we should the one we created with name as "ebs-sc"

# Verify PVC and PV
kubectl get pvc
kubectl get pv
Observation:
1. Status should be in BOUND state

# Verify Deployments
kubectl get deploy
Observation:
1. We should see both deployments in default namespace
- mysql
- usermgmt-webapp

# Verify Pods
kubectl get pods
Observation:
1. You should see both pods running

# Describe both pods and review events
kubectl describe pod <POD-NAME>
kubectl describe pod mysql-6fdd448876-hdhnm
kubectl describe pod usermgmt-webapp-cfd4c7-fnf9s

# Review UserMgmt Pod Logs
kubectl logs -f usermgmt-webapp-cfd4c7-fnf9s
Observation:
1. Review the logs and ensure it is successfully connected to MySQL POD

# Verify Services
kubectl get svc
```

## Step-17: Connect to MySQL Database Pod
```t
# Connect to MySQL Database 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -pdbpassword11

# Verify usermgmt schema got created which we provided in ConfigMap
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;

Observation:
1. If UserMgmt WebApp container successfully started, it will connect to Database and create the default user named admin101
Username: admin101
Password: password101
```
## Step-18: Access Sample Application
```t
# Verify Services
kubectl get svc

# Access using browser
http://<CLB-DNS-URL>
http://<NLB-DNS-URL>
Username: admin101
Password: password101

# Create Users and Verify using UserMgmt WebApp in browser
admin102/password102
admin103/password103

# Verify the same in MySQL DB
## Connect to MySQL Database 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -pdbpassword11

## Verify usermgmt schema got created which we provided in ConfigMap
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
```

## Step-19: Node Port Service Port - Update Node Security Group
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


## Step-20: Access Sample using NodePort Service 
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
Username: admin101
Password: password101
```

## Step-21: Remove Inbound Rule added  
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Remove the NodePort Rule which we added.

## Step-17: Clean-Up - UserMgmt WebApp Kubernetes Resources
```t
# Change Directory
cd 16-EBS-Kubernetes-SampleApp-Terraform/03-terraform-manifests-UMS-WebApp

# Delete Kubernetes  Resources using Terraform
terraform apply -destroy -auto-approve

# Delete Provider Plugins
rm -rf .terraform*

# Verify Kubernetes Resources
kubectl get pods
kubectl get svc
Observation: 
1. All UserMgmt Web App related Kubernetes resources should be deleted
``` 

## Step-18: Clean-Up - EBS CSI Driver Uninstall
```t
# Change Directory
cd 16-EBS-Kubernetes-SampleApp-Terraform/02-ebs-terraform-manifests

# Delete Kubernetes  Resources using Terraform
terraform apply -destroy -auto-approve

# Delete Provider Plugins
rm -rf .terraform*

# Verify Kubernetes Resources
kubectl -n kube-system get pods
Observation: 
1. All EBS CSI Driver related Kubernetes resources should be deleted
``` 

## Step-19: Clean-Up - EKS Cluster (Optional)
- If we are continuing to next section immediately ignore this step, else delete EKS Cluster to save cost.
```t
# Change Directory
cd 16-EBS-Kubernetes-SampleApp-Terraform/01-ekscluster-terraform-manifests

# Delete Kubernetes  Resources using Terraform
terraform apply -destroy -auto-approve

# Delete Provider Plugins
rm -rf .terraform*
``` 

