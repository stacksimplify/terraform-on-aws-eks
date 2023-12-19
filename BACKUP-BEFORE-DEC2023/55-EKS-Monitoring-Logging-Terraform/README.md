---
title: AWS EKS Monitoring and Logging with Terraform
description: Learn to AWS EKS Monitoring and Logging with Terraform
---

## Step-01: Introduction
- EKS Monitoring and Logging 


### Pre-requisites
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

## Step-02: Project-01: Add CloudWatchAgentServerPolicy IAM Policy to Node Group IAM Role
- **File Name:** `01-ekscluster-terraform-manifests/c5-04-iamrole-for-eks-nodegroup.tf`
```t
# CloudWatchAgentServerPolicy for AWS CloudWatch Container Insights
resource "aws_iam_role_policy_attachment" "eks_cloudwatch_container_insights" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

# Change Directory
01-ekscluster-terraform-manifests

# Update EKS Cluster Terraform project
terraform validate
terraform plan
terraform apply -auto-approve
```

## Step-03: Project-02: Review Terraform Manifests
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
1. c1-versions.tf
  - Create DynamoDB Table `dev-eks-cloudwatch-agent`
2. c2-remote-state-datasource.tf
3. c3-01-generic-variables.tf
4. c3-02-local-values.tf
5. terraform.tfvars

## Step-04: c4-01-terraform-providers.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
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

## Step-05: c4-02-cwagent-namespace.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
## Resource: Namespace
resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}
```

## Step-06: c4-03-cwagent-service-accounts-cr-crb.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
# Resource: Service Account, ClusteRole, ClusterRoleBinding

# Datasource
data "http" "get_cwagent_serviceaccount" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

# Datasource: kubectl_file_documents 
# This provider provides a data resource kubectl_file_documents to enable ease of splitting multi-document yaml content.
data "kubectl_file_documents" "cwagent_docs" {
    content = data.http.get_cwagent_serviceaccount.body
}

# Resource: kubectl_manifest which will create k8s Resources from the URL specified in above datasource
resource "kubectl_manifest" "cwagent_serviceaccount" {
    depends_on = [kubernetes_namespace_v1.amazon_cloudwatch]
    for_each = data.kubectl_file_documents.cwagent_docs.manifests
    yaml_body = each.value
}
```

## Step-07: c4-04-cwagent-configmap.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
# Resource: CloudWatch Agent ConfigMap
resource "kubernetes_config_map_v1" "cwagentconfig_configmap" {
  metadata {
    name = "cwagentconfig"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name 
  }
  data = {
    "cwagentconfig.json" = jsonencode({
      "logs": {
        "metrics_collected": {
          "kubernetes": {
            "metrics_collection_interval": 60
          }
        },
        "force_flush_interval": 5
      }
    })
  }
}
```

## Step-08: c4-05-cwagent-daemonset.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
# Resource: Daemonset

# Datasource
data "http" "get_cwagent_daemonset" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

# Resource: kubectl_manifest which will create k8s Resources from the URL specified in above datasource
resource "kubectl_manifest" "cwagent_daemonset" {
    depends_on = [
      kubernetes_namespace_v1.amazon_cloudwatch,
      kubernetes_config_map_v1.cwagentconfig_configmap
      ]
    yaml_body = data.http.get_cwagent_daemonset.body
}
```

## Step-09: c5-01-fluentbit-configmap.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
# Resource: FluentBit Agent ConfigMap
resource "kubernetes_config_map_v1" "fluentbit_configmap" {
  metadata {
    name = "fluent-bit-cluster-info"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name 
  }
  data = {
    "cluster.name" = data.terraform_remote_state.eks.outputs.cluster_id
    "http.port"   = "2020"
    "http.server" = "On"
    "logs.region" = var.aws_region
    "read.head" = "Off"
    "read.tail" = "On"
  }
}
```

## Step-10: c5-02-fluentbit-daemonset.tf
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
# Resources: FluentBit 
## - ServiceAccount
## - ClusterRole
## - ClusterRoleBinding
## - ConfigMap: fluent-bit-config
## - DaemonSet

# Datasource
data "http" "get_fluentbit_resources" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

# Datasource: kubectl_file_documents 
# This provider provides a data resource kubectl_file_documents to enable ease of splitting multi-document yaml content.
data "kubectl_file_documents" "fluentbit_docs" {
    content = data.http.get_fluentbit_resources.body
}

# Resource: kubectl_manifest which will create k8s Resources from the URL specified in above datasource
resource "kubectl_manifest" "fluentbit_resources" {
  depends_on = [
    kubernetes_namespace_v1.amazon_cloudwatch,
    kubernetes_config_map_v1.fluentbit_configmap,
    kubectl_manifest.cwagent_daemonset
    ]
  for_each = data.kubectl_file_documents.fluentbit_docs.manifests    
  yaml_body = each.value
}
```

## Step-11: Project-02: Execute Terraform Commands
- **Project Folder:** 02-cloudwatchagent-fluentbit-terraform-manifests
```t
# Change Directory
cd 02-cloudwatchagent-fluentbit-terraform-manifests

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terrafom Apply
terraform apply -auto-approve
```

## Step-13: Verify AWS CloudWatch Agent k8s Resources
```t
# List Namespaces
kubectl get ns

# Verify Service Account
kubectl -n amazon-cloudwatch get sa

# Verify Cluster Role and Cluster Role Binding
kubectl get clusterrole cloudwatch-agent-role 
kubectl get clusterrolebinding cloudwatch-agent-role-binding

# Verify Cluster Role and Cluster Role Binding (Output as YAML)
kubectl get clusterrole cloudwatch-agent-role -o yaml
kubectl get clusterrolebinding cloudwatch-agent-role-binding -o yaml
Observation: 
1. Verify the "subjects" section in crb output

# Verify CloudWatch Agent ConfigMap
kubectl -n amazon-cloudwatch get cm cwagentconfig
kubectl -n amazon-cloudwatch describe cm cwagentconfig
kubectl -n amazon-cloudwatch get cm cwagentconfig -o yaml

# List Daemonset
kubectl -n amazon-cloudwatch get ds

# List Pods 
kubectl -n amazon-cloudwatch get pods 

# Describe Pod
kubectl -n amazon-cloudwatch describe pod <pod-name>

# Verify Pod Logs
kubectl -n amazon-cloudwatch logs -f <pod-name>
```


## Step-14: Verify FluentBit k8s Resources
```t
# List Service Account
kubectl -n amazon-cloudwatch get sa

# List Cluster Role and Cluster Role Binding
kubectl get clusterrole fluent-bit-role
kubectl get clusterrolebinding fluent-bit-role-binding

# List Cluster Role and Cluster Role Binding (Output as YAML)
kubectl get clusterrole fluent-bit-role -o yaml
kubectl get clusterrolebinding fluent-bit-role-binding -o yaml
Observation: 
1. Verify the "subjects" in crb output

# List ConfigMap (FluentBit - Cluster Info ConfigMap)
kubectl -n amazon-cloudwatch get configmap

# Describe ConfigMap (FluentBit - Cluster Info ConfigMap)
kubectl -n amazon-cloudwatch describe configmap fluent-bit-cluster-info

# ConfigMap Output as YAML (FluentBit - Cluster Info ConfigMap)
kubectl -n amazon-cloudwatch get configmap fluent-bit-cluster-info -o yaml

# List ConfigMap (FluentBit Config - ConfigMap)
kubectl -n amazon-cloudwatch get configmap

# Describe ConfigMap (FluentBit Config - ConfigMap)
kubectl -n amazon-cloudwatch describe configmap fluent-bit-config

# ConfigMap Output as YAML (FluentBit Config - ConfigMap)
kubectl -n amazon-cloudwatch get configmap fluent-bit-config -o yaml

# List Daemonsets 
kubectl -n amazon-cloudwatch get ds
Observation:
1. Verify "fluent-bit" Daemonset

# List Pods (fluent-bit)
kubectl -n amazon-cloudwatch get pods

# Describe Pod (fluent-bit)
kubectl -n amazon-cloudwatch describe pod <POD-NAME>
kubectl -n amazon-cloudwatch describe pod fluent-bit-hkd5k  

# Verify Pod logs (fluent-bit)
kubectl -n amazon-cloudwatch logs -f <POD-NAME>
kubectl -n amazon-cloudwatch logs -f fluent-bit-hkd5k  
```

## Step-15: Deploy Sample Application myapp1
- **Project Folder:** 03-sample-app-test-container-insights
- **Review Terraform Manifests**
1. 01-Deployment.yaml
2. 02-CLB-LoadBalancer-Service.yaml
3. 03-NLB-LoadBalancer-Service.yaml
```t
# Deploy Sample Application
kubectl apply -f 03-sample-app-test-container-insights
```

## Step-16: Verify CloudWatch Container Insights in AWS Mgmt Console
### Step-16-01: Verify Container Insights - Resources & Alarms
- Go to Services -> CloudWatch -> Insights -> Container Insights
- Resources: 
  - amazon-cloudwatch  (Type: Namespace)
  - hr-dev-eksdemo1 (Type: Cluster)
  - myap1-deployment (Type: EKS Pod)
- Alarms
  - Review Alarms

### Step-16-02: Verify Container Insights - Performance Monitoring
- Go to Services -> CloudWatch -> Insights -> Container Insights
- In Drop Down, Select **Performance Monitoring** 
  - Default: EKS Cluster
- Change to 
  - EKS Namespaces
  - Review the output
- Change to 
  - EKS Nodes
  - Review the output
- Change to 
  - EKS Pods
  - Review the output    

### Step-16-03: Verify Container Insights - Container Map
- Go to Services -> CloudWatch -> Insights -> Container Insights
- In Drop Down, Select **Container Map** 
  - Review **CPU Mode**
  - Review **Memory Mode**
  - Review **Turn Off Heat Map**

## Step-17: AWS CloudWatch Logs
### Step-17-01: EKS Cluster Control Plane Logs
- Go to Services -> CloudWatch -> Logs -> Log Groups
- **Log Group:** 	/aws/eks/hr-dev-eksdemo1/cluster
- For a different clustername it should be `/aws/eks/<CLUSTER_NAME>/cluster`
- This is created when we have enabled the argument in EKS Cluster Resource `aws_eks_cluster`
- **File Name:** 01-ekscluster-terraform-manifests/c5-06-eks-cluster.tf
```t
# Enable EKS Cluster Control Plane Logging
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

### Step-17-02: Performance Logs
- These logs are enabled when we install the **Cloud Watch Container Insights** as part of `step-04` of this section
- **Log Group:** /aws/containerinsights/hr-dev-eksdemo1/performance
- For a different clustername it should be `/aws/containerinsights/<CLUSTER_NAME>/performance`

### Step-17-03: Fluent Bit Logs
- These logs are enabled when we install the **Fluent Bit** as part of `step-06` of this section
- **Log Groups:**
  - /aws/containerinsights/hr-dev-eksdemo1/application
  - /aws/containerinsights/hr-dev-eksdemo1/dataplane
  - /aws/containerinsights/hr-dev-eksdemo1/host
- **Log Groups:** For a different clustername it should be
  - /aws/containerinsights/<CLUSTER_NAME>/application
  - /aws/containerinsights/<CLUSTER_NAME>/dataplane
  - /aws/containerinsights/<CLUSTER_NAME>/host


### Step-17-04: Fluent Bit Logs  - myapp1 Logs
```t
# Access Sample
curl http://<CLB-DNS-URL>
curl http://<NLB-DNS-URL>

# Verify Logs
1. Go to Services -> CloudWatch -> Logs -> Log Groups
2. Click on "/aws/containerinsights/hr-dev-eksdemo1/application"
3. Search for Log Steam containing name "myapp1"
Example: ip-10-0-1-63.ec2.internal-application.var.log.containers.myapp1-deployment-58ccb86d9-2q88h_default_myapp1-container-14cfc9c146e126db0d58d2a6534e2c21a37a954fbda1e28f46bfe5f5ace18c84.log
4. Verify that log
```

## Step-18: CleanUp - Sample Application
```t
# Delete Sample Application
kubectl delete -f 03-sample-app-test-container-insights
```

## Step-19: Clean-Up Project-02
```t
# Change Directory
cd 02-cloudwatchagent-fluentbit-terraform-manifests

# Terraform Destroy
terraform apply -destroy -auto-approve
rm -rf .terraform*
```


## Reference
- [AWS Cloud Watch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-EKS.html)
- [Troubleshooting Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights-troubleshooting.html)
- [Fluent Bit Setup](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html)
- [Reference Document](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html)
- [GIT REPO FOR DEPLOYMENT MODES](https://github.com/aws-samples/amazon-cloudwatch-container-insights/tree/master/k8s-deployment-manifest-templates/deployment-mode)