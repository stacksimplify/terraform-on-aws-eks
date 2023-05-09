---
title: AWS EKS Vertical Pod Autoscaler with Terraform
description: Learn to implement AWS EKS Vertical Pod Autoscaler with Terraform
---

## Step-01: Introduction
- Install Metrics Server
- Deploy VPA (Vertical Pod Autoscaler)

### Pre-requisites-1: EKS Cluster
- EKS Cluster is created and ready for use
```t
# Change Directory
01-ekscluster-terraform-manifests

# Create EKS Cluster
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# If EKS Cluster already create as per previous sections JUST VERIFY
terraform init
terraform state list

# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```
### Pre-requisite-2: Metrics Server
- Metrics Server deployed and ready
```t
# Change Directory 
cd 02-k8s-metrics-server-terraform-manifests

# Deploy Metrics Server
terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# If Metrics Server already deployed as per previous sections JUST VERIFY
terraform init
terraform state list

# Verify Metrics Server Pods
kubectl -n kube-system get pods

# Verify Metrics for pods
kubectl top pods -n kube-system
```

## Step-02: Install OpenSSL in your Local Terminal
- Please upgrade openssl to version 1.1.1 or higher (needs to support -addext option))
```t
# Install OpenSSL
brew update
brew install openssl

# After Install  (Update in your BASH Profile if the installation recommends)
export PATH="/usr/local/opt/openssl@3/bin:$PATH"
Refer Link: https://stackoverflow.com/questions/62195898/openssl-still-pointing-to-libressl-2-8-3

# Verify your OpenSSL Version
openssl version 

## Sample Output
Kalyans-MacBook-Pro:03-vpa-install-terraform-manifests kdaida$ openssl version
OpenSSL 3.0.3 3 May 2022 (Library: OpenSSL 3.0.3 3 May 2022)
Kalyans-MacBook-Pro:03-vpa-install-terraform-manifests kdaida$ 
```

## Step-03: Key Pre-requisite: Your local terminal should be configured with kubeconfig for kubectl
```t
# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

# Verify Kubernetes Worker Nodes using kubectl
kubectl get nodes
kubectl get nodes -o wide
```

## Step-04: Understand about Null Resource 
- The `null_resource` resource implements the standard resource lifecycle but takes no further action.
- [Terraform Null Resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)

## Step-05: Understand about Terraform Provisioners
- Provisioners can be used to model specific actions on the local machine or on a remote machine in order to prepare servers or other infrastructure objects for service.
- File Provisioner
- local-exec Provisioner
- remote-exec Provisioner
- [Terraform Provisioners](https://www.terraform.io/language/resources/provisioners/syntax)

## Step-06: Project-03: c1-versions.tf
- **Project Folder:** 03-vpa-install-terraform-manifests
```t
# Terraform Settings Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.1"
    }
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-on-aws-eks"
    key    = "dev/eks-vpa-install/terraform.tfstate"
    region = "us-east-1" 

    # For State Locking
    dynamodb_table = "dev-eks-vpa-install"    
  }     
}

provider "null" {
  # Configuration options
}
```

## Step-07: Project-03: c2-vpa-install.tf
- **Project Folder:** 03-vpa-install-terraform-manifests
```t
# 1. Key Requirement-1: Install OpenSSL in local terminal whose version is 1.1.1 or higher 
# 2. Key Requirement-2: Configure kubeconfig for kubectl in your local terminal

# Resource-1: Null Resource: Clone GitHub Repository
resource "null_resource" "git_clone" {
  provisioner "local-exec" {
    command = "git clone git@github.com:kubernetes/autoscaler.git"
  }
}


# # Resource-2: Null Resource: Install Vertical Pod Autoscaler
resource "null_resource" "install_vpa" {
  depends_on = [null_resource.git_clone]
 provisioner "local-exec" { 
    command = "${path.module}/autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh"
  }
}

# Resource-3: Null Resource: Remove autoscaler folder
resource "null_resource" "remove_git_clone_autoscaler_folder" {
 provisioner "local-exec" { 
    command = "rm -rf  ${path.module}/autoscaler"
    when = destroy
  }
}


# Resource-4: Null Resource: Uninstall Vertical Pod Autoscaler
resource "null_resource" "uninstall_vpa" {
  depends_on = [null_resource.remove_git_clone_autoscaler_folder]
 provisioner "local-exec" { 
    command = "${path.module}/autoscaler/vertical-pod-autoscaler/hack/vpa-down.sh"
    when = destroy
  }
}
```

## Step-08: Project-03: Execute Terraform Commands
```t
# Change Directory
03-vpa-install-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform plan

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-09: Verify k8s VPA Resources
```t
# List Deployments
kubectl -n kube-system get deploy
Observation:  We should see three deployments
1. vpa-admission-controller
2. vpa-recommender
3. vpa-updater

# List Pods
kubectl -n kube-system get pods
Observation:  We should see pods related to 3 VPA deployments

# List & Describe Secrets
kubectl -n kube-system get secrets vpa-tls-certs
kubectl -n kube-system describe secrets vpa-tls-certs
kubectl -n kube-system get secrets vpa-tls-certs -o yaml

# List Services
kubectl -n kube-system get svc
Observation: We should see the vpa-webhook service

# Describe Service: vpa-webhook
kubectl -n kube-system describe svc vpa-webhook
Observation: Review the Selectors
1. We should see "app=vpa-admission-controller"
2. Which means requests from this service sent to VPA Admission Controller

# Kubernetes Custom Resource Definitions
kubectl get customresourcedefinition
kubectl get customresourcedefinition|grep verticalpodautoscalers

# There are many other resources created as part of VPA deployment
1. Service Accounts
2. Cluster Role
3. Cluster Role Binding.
4. Custom Resource Definitions
All those things you can review using the below deployment log
```


### Sample Log for VPA Install
```t
null_resource.install_vpa: Creating...
null_resource.install_vpa: Provisioning with 'local-exec'...
null_resource.install_vpa (local-exec): Executing: ["/bin/sh" "-c" "./autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh"]
null_resource.install_vpa (local-exec): customresourcedefinition.apiextensions.k8s.io/verticalpodautoscalercheckpoints.autoscaling.k8s.io created
null_resource.install_vpa (local-exec): customresourcedefinition.apiextensions.k8s.io/verticalpodautoscalers.autoscaling.k8s.io created
null_resource.install_vpa: Still creating... [10s elapsed]
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:metrics-reader created
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:vpa-actor created
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:vpa-checkpoint-actor created
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:evictioner created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:metrics-reader created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:vpa-actor created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:vpa-checkpoint-actor created
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:vpa-target-reader created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:vpa-target-reader-binding created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:vpa-evictionter-binding created
null_resource.install_vpa (local-exec): serviceaccount/vpa-admission-controller created
null_resource.install_vpa: Still creating... [20s elapsed]
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:vpa-admission-controller created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:vpa-admission-controller created
null_resource.install_vpa (local-exec): clusterrole.rbac.authorization.k8s.io/system:vpa-status-reader created
null_resource.install_vpa (local-exec): clusterrolebinding.rbac.authorization.k8s.io/system:vpa-status-reader-binding created
null_resource.install_vpa (local-exec): serviceaccount/vpa-updater created
null_resource.install_vpa (local-exec): deployment.apps/vpa-updater created
null_resource.install_vpa (local-exec): serviceaccount/vpa-recommender created
null_resource.install_vpa (local-exec): deployment.apps/vpa-recommender created
null_resource.install_vpa (local-exec): Generating certs for the VPA Admission Controller in /tmp/vpa-certs.
null_resource.install_vpa: Still creating... [30s elapsed]
null_resource.install_vpa (local-exec): Certificate request self-signature ok
null_resource.install_vpa (local-exec): subject=CN = vpa-webhook.kube-system.svc
null_resource.install_vpa (local-exec): Uploading certs to the cluster.
null_resource.install_vpa (local-exec): secret/vpa-tls-certs created
null_resource.install_vpa (local-exec): Deleting /tmp/vpa-certs.
null_resource.install_vpa (local-exec): deployment.apps/vpa-admission-controller created
null_resource.install_vpa (local-exec): service/vpa-webhook created
null_resource.install_vpa: Creation complete after 36s [id=4418919568449001144]
Releasing state lock. This may take a few moments...
```


## Step-11: Project-04: 01-vpa-demo-app.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpa-demo-deployment
  labels:
    app: vpa-nginx
spec:
  replicas: 4
  selector:
    matchLabels:
      app: vpa-nginx
  template:
    metadata:
      labels:
        app: vpa-nginx
    spec:
      containers:
      - name: vpa-nginx
        image: stacksimplify/kubenginx:1.0.0
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "5m"       
            memory: "5Mi"            
---
apiVersion: v1
kind: Service
metadata:
  name: vpa-demo-service-nginx
  labels:
    app: vpa-nginx
spec:
  type: ClusterIP
  selector:
    app: vpa-nginx
  ports:
  - port: 80
    targetPort: 80   
```

## Step-12: Project-04: 02-vpa-resource.yaml
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       vpa-demo-deployment
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: "nginx"
      minAllowed:
        cpu: "5m"
        memory: "5Mi"
      maxAllowed:
        cpu: "20m"
        memory: "20Mi"    
```

## Step-13: Deploy Sample App 
```t
# Deploy Sample App
kubectl apply -f 04-vpa-demo-yaml/01-vpa-demo-app.yaml

# Verify Pods
kubectl get pods

# Describe Pod to Review Pod Request CPU and Memory
kubectl describe pod <POD-NAME>
kubectl describe pod vpa-demo-deployment-cb5475fc8-f66bv 

### SAMPLE OUTPUT 
    Requests:
      cpu:        5m
      memory:     5Mi
```

## Step-14: Deploy VPA Resource
```t
# Deply VPA Resource
kubectl apply -f 04-vpa-demo-yaml/02-vpa-resource.yaml

# List VPA
kubectl get vpa

### Sample Output with Recommendations
Kalyans-MacBook-Pro:53-EKS-Vertical-Pod-Autoscaler-Install kdaida$ kubectl get vpa
NAME         MODE   CPU   MEM       PROVIDED   AGE
my-app-vpa   Auto   25m   262144k   True       27s
Kalyans-MacBook-Pro:53-EKS-Vertical-Pod-Autoscaler-Install kdaida$ 


# Describe VPA
kubectl describe vpa <VPA-NAME>
kubectl describe vpa my-app-vpa

# List Pods and Watch (New Terminal)
kubectl get pods -w
Observation:
1. Out of 4 pods 2 pods will get terminated and recreated with VPA recommended CPU and Memory Resources
2. After 60 seconds, other 2 pods also will get terminated and recreated with VPA recommended CPU and Memory Resources

# Describe Pod to Review Pod Request CPU and Memory
kubectl describe pod <POD-NAME>
kubectl describe pod vpa-demo-deployment-cb5475fc8-f66bv 

### SAMPLE OUTPUT 
    Requests:
      cpu:        25m
      memory:     262144k

Observation:
1. VPA Recommended lower bound CPU and Memory resource values applied for pods
```

## Step-15: Clean-Up VPA Sample and VPA Resource
```t
# Delete VPA Sample App and VPA Reource
kubectl delete -f 04-vpa-demo-yaml/
```

## Step-16: Uncomment Resource Policy in VPA Resource: 02-vpa-resource.yaml
- **Project Folder:**  04-vpa-demo-yaml
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       vpa-demo-deployment
  updatePolicy:
    updateMode: "Auto"
# Resource Policy - Uncomment at step-15   
  resourcePolicy:
    containerPolicies:
    - containerName: "vpa-nginx"
      minAllowed:
        cpu: "5m"
        memory: "5Mi"
      maxAllowed:
        cpu: "20m"
        memory: "20Mi"    
```

## Step-17: Deploy VPA Resource with Resource Policy and VPA Sample App
```t
# Deploy VPA Sample App and VPA Reource
kubectl apply -f 04-vpa-demo-yaml/
```

## Step-18: Verify Changes after VPA Resource policy update
```t
# List VPA
kubectl get vpa

### Sample Output with Recommendations
Kalyans-MacBook-Pro:53-EKS-Vertical-Pod-Autoscaler-Install kdaida$ kubectl get vpa
NAME         MODE   CPU   MEM    PROVIDED   AGE
my-app-vpa   Auto   20m   20Mi   True       76s
Kalyans-MacBook-Pro:53-EKS-Vertical-Pod-Autoscaler-Install kdaida$ 

Observation:
1. We can see here VPA Recommended recommended the CPU and MEM values as max values we have defined in VPA Resource Policy (CPU 20m, Memory 20Mi)

# Describe VPA
kubectl describe vpa <VPA-NAME>
kubectl describe vpa my-app-vpa

# List Pods and Watch (New Terminal)
kubectl get pods -w
Observation:
1. Out of 4 pods 2 pods will get terminated and recreated with VPA recommended CPU and Memory Resources
2. After 60 seconds, other 2 pods also will get terminated and recreated with VPA recommended CPU and Memory Resources

# Describe Pod to Review Pod Request CPU and Memory
kubectl describe pod <POD-NAME>
kubectl describe pod vpa-demo-deployment-cb5475fc8-f66bv 

### SAMPLE OUTPUT 
    Requests:
      cpu:        20m
      memory:     20Mi

Observation:
1. VPA Recommended values from VPA resource policy max values and same updated for pods
```

## Step-19: Clean-Up VPA Sample App and VPA Resource
```t
# Delete VPA Sample App and VPA Reource
kubectl delete -f 04-vpa-demo-yaml/
```

## Step-20: Project-05: Review Terraform Manifests
- **Project Folder:** 05-vpa-demo-terraform-manifests
1. c1-versions.tf
  - Create new DynamoDB Table `dev-vpa-demo-app`
2. c2-remote-state-datasource.tf
3. c3-01-generic-variables.tf
4. c3-02-local-values.tf

## Step-21: c4-01-terraform-providers.tf
- **Project Folder:** 05-vpa-demo-terraform-manifests
```t
# Terraform AWS Provider Block
provider "aws" {
  region = var.aws_region
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

# Terraform kubectl Provider
provider "kubectl" {
  # Configuration options
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```

## Step-22: c4-02-vpa-sample-app-deployment.tf
- **Project Folder:** 05-vpa-demo-terraform-manifests
```t
# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "vpa_demo_app" {
  metadata {
    name = "vpa-demo-deployment" 
    labels = {
      app = "vpa-nginx"
    }
  } 
 
  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "vpa-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "vpa-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kubenginx:1.0.0"
          name  = "vpa-nginx"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu = "5m"
              memory = "5Mi"
            }
          }
          }
        }
      }
    }
}
```

## Step-23: c4-03-vpa-sample-app-service.tf
- **Project Folder:** 05-vpa-demo-terraform-manifests
```t
# Kubernetes Service Manifest (Type: Cluster IP Service)
resource "kubernetes_service_v1" "myapp3_cip_service" {
  metadata {
    name = "vpa-demo-service-nginx" 
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.vpa_demo_app.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

```

## Step-24: c4-04-vpa-resource.tf
- **Vertical Pod Autoscaler Terraform Resource**
- As on today, we don't have VPA Terraform resource in Terraform Kubernetes provider
- That said we will demonstrate this using YAML manifests
- If we want VPA Resource using Terraform we need to use the [kubectl_manifest](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/kubectl_manifest) resource from [kubectl provider](https://registry.terraform.io/providers/gavinbunney/kubectl/latest)

- **Project Folder:** 05-vpa-demo-terraform-manifests
```t
resource "kubectl_manifest" "vpa_resource" {
    yaml_body = <<YAML
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       vpa-demo-deployment
  updatePolicy:
    updateMode: "Auto"
# Resource Policy - Uncomment at step-15   
  resourcePolicy:
    containerPolicies:
    - containerName: "vpa-nginx"
      minAllowed:
        cpu: "5m"
        memory: "5Mi"
      maxAllowed:
        cpu: "20m"
        memory: "20Mi"    
YAML
}
```

## Step-25: Execute Terraform Commands
```t
# Change Directory
cd 05-vpa-demo-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-26: Verify Resources
```t
# List VPA
kubectl get vpa

### Sample Output with Recommendations
Kalyans-MacBook-Pro:53-EKS-Vertical-Pod-Autoscaler-Install kdaida$ kubectl get vpa
NAME         MODE   CPU   MEM    PROVIDED   AGE
my-app-vpa   Auto   20m   20Mi   True       76s
Kalyans-MacBook-Pro:53-EKS-Vertical-Pod-Autoscaler-Install kdaida$ 

Observation:
1. We can see here VPA Recommended recommended the CPU and MEM values as max values we have defined in VPA Resource Policy (CPU 20m, Memory 20Mi)

# Describe VPA
kubectl describe vpa <VPA-NAME>
kubectl describe vpa my-app-vpa

# List Pods and Watch (New Terminal)
kubectl get pods -w
Observation:
1. Out of 4 pods 2 pods will get terminated and recreated with VPA recommended CPU and Memory Resources
2. After 60 seconds, other 2 pods also will get terminated and recreated with VPA recommended CPU and Memory Resources

# Describe Pod to Review Pod Request CPU and Memory
kubectl describe pod <POD-NAME>
kubectl describe pod vpa-demo-deployment-cb5475fc8-f66bv 

### SAMPLE OUTPUT 
    Requests:
      cpu:        20m
      memory:     20Mi

Observation:
1. VPA Recommended values from VPA resource policy max values and same updated for pods
```

## Step-27: Project-05: Clean-Up
```t
# Change Directory
cd 05-vpa-demo-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-28: Project-02: Clean-Up Metrics Server
```t
# Change Directory
cd 02-k8s-metrics-server-terraform-manifests

# Terraform Destroy 
terraform init
terraform apply -destroy -auto-approve
rm -rf .terraform*
```

## Step-29: Project-01: Clean-Up EKS Cluster (Optional)
```t
# Change Directory
cd 01-ekscluster-terraform-manifests

# Terraform Destroy 
terraform init
terraform apply -destroy -auto-approve
rm -rf .terraform*
```



## References
- [Metrics Server Helm Chart](https://artifacthub.io/packages/helm/metrics-server/metrics-server)
- [Metrics Server Git Repo](https://github.com/kubernetes-sigs/metrics-server/)
- [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

