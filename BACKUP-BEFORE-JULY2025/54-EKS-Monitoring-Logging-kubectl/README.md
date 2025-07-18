---
title: AWS EKS Monitoring and Logging with kubectl
description: Learn to AWS EKS Monitoring and Logging with kubectl
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

## Step-03: Create AWS CloudWatch Agent ConfigMap YAML Manifest
- **File Name:** `02-cwagent-container-insights/01-cw-agent-configmap.yaml`
```t
# Download ConfigMap for the CloudWatch agent (Download and update)
curl -O https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-configmap.yaml

# Remove the line
            "cluster_name": "{{cluster_name}}",
```
- **CloudWatch Agent ConfigMap after changes**
```yaml
# create configmap for cwagent config
apiVersion: v1
data:
  # Configuration is in Json format. No matter what configure change you make,
  # please keep the Json blob valid.
  cwagentconfig.json: |
    {
      "logs": {
        "metrics_collected": {
          "kubernetes": {
            "metrics_collection_interval": 60
          }
        },
        "force_flush_interval": 5
      }
    }
kind: ConfigMap
metadata:
  name: cwagentconfig
  namespace: amazon-cloudwatch
```

## Step-03: Create FluentBit ConfigMap YAML Manifest
- **File Name:** `02-cwagent-container-insights/02-cw-fluentbit-configmap.yaml`
- Update Cluster Name `cluster.name: hr-dev-eksdemo1`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-cluster-info
  namespace: amazon-cloudwatch
data:
  cluster.name: hr-dev-eksdemo1
  http.port: "2020"
  http.server: "On"
  logs.region: us-east-1
  read.head: "Off"
  read.tail: "On"

## ConfigMap named fluent-bit-cluster-info with the cluster name and the Region to send logs to
## Set Fluent Bit ConfigMap Values
#ClusterName=cluster-name
#RegionName=cluster-region
#FluentBitHttpPort='2020'
#FluentBitReadFromHead='Off'
#[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
#[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'

# Additional Note-1: In this command, the FluentBitHttpServer for monitoring plugin metrics is on by default. To turn it off, change the third line in the command to FluentBitHttpPort='' (empty string) in the command.
# Additional Note-2:Also by default, Fluent Bit reads log files from the tail, and will capture only new logs after it is deployed. If you want the opposite, set FluentBitReadFromHead='On' and it will collect all logs in the file system.
```

## Step-04: Install AWS CloudWatch Agent 
- **Deployment Mode for AWS CloudWatch Agent:** DaemonSet
- [Reference Document](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html)
- [GIT REPO FOR DEPLOYMENT MODES](https://github.com/aws-samples/amazon-cloudwatch-container-insights/tree/master/k8s-deployment-manifest-templates/deployment-mode)
```t
# Create Namespace for AWS CloudWatch Agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

# Create a Service Account for AWS CloudWatch Agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml

# Create a ConfigMap for the AWS CloudWatch agent 
kubectl apply -f 02-cwagent-container-insights/01-cw-agent-configmap.yaml

# Deploy the AWS CloudWatch agent as a DaemonSet 
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml
```
## Step-05: Verify AWS CloudWatch Agent k8s Resources
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

## Step-06: Deploy FluentBit
- [Set up Fluent Bit as a DaemonSet to send logs to CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html)
```t
# Create FluentBit ConfigMap (Update EKS Cluster Name in 02-cw-fluentbit-configmap.yaml)
kubectl apply -f 02-cwagent-container-insights/02-cw-fluentbit-configmap.yaml

# Deploy FluentBit Optimized Configuration
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml
```

## Step-07: Verify FluentBit k8s Resources
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

## Step-08: Deploy Sample Application myapp1
- **Project Folder:** 03-sample-app-test-container-insights
- **Review Terraform Manifests**
1. 01-Deployment.yaml
2. 02-CLB-LoadBalancer-Service.yaml
3. 03-NLB-LoadBalancer-Service.yaml
```t
# Deploy Sample Application
kubectl apply -f 03-sample-app-test-container-insights
```

## Step-09: Verify CloudWatch Container Insights in AWS Mgmt Console
### Step-09-01: Verify Container Insights - Resources & Alarms
- Go to Services -> CloudWatch -> Insights -> Container Insights
- Resources: 
  - amazon-cloudwatch  (Type: Namespace)
  - hr-dev-eksdemo1 (Type: Cluster)
  - myap1-deployment (Type: EKS Pod)
- Alarms
  - Review Alarms

### Step-09-02: Verify Container Insights - Performance Monitoring
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

### Step-09-03: Verify Container Insights - Container Map
- Go to Services -> CloudWatch -> Insights -> Container Insights
- In Drop Down, Select **Container Map** 
  - Review **CPU Mode**
  - Review **Memory Mode**
  - Review **Turn Off Heat Map**

## Step-10: AWS CloudWatch Logs
### Step-10-01: EKS Cluster Control Plane Logs
- Go to Services -> CloudWatch -> Logs -> Log Groups
- **Log Group:** 	/aws/eks/hr-dev-eksdemo1/cluster
- For a different clustername it should be `/aws/eks/<CLUSTER_NAME>/cluster`
- This is created when we have enabled the argument in EKS Cluster Resource `aws_eks_cluster`
- **File Name:** 01-ekscluster-terraform-manifests/c5-06-eks-cluster.tf
```t
# Enable EKS Cluster Control Plane Logging
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

### Step-10-02: Performance Logs
- These logs are enabled when we install the **Cloud Watch Container Insights** as part of `step-04` of this section
- **Log Group:** /aws/containerinsights/hr-dev-eksdemo1/performance
- For a different clustername it should be `/aws/containerinsights/<CLUSTER_NAME>/performance`

### Step-10-03: Fluent Bit Logs
- These logs are enabled when we install the **Fluent Bit** as part of `step-06` of this section
- **Log Groups:**
  - /aws/containerinsights/hr-dev-eksdemo1/application
  - /aws/containerinsights/hr-dev-eksdemo1/dataplane
  - /aws/containerinsights/hr-dev-eksdemo1/host
- **Log Groups:** For a different clustername it should be
  - /aws/containerinsights/<CLUSTER_NAME>/application
  - /aws/containerinsights/<CLUSTER_NAME>/dataplane
  - /aws/containerinsights/<CLUSTER_NAME>/host


### Step-10-04: Fluent Bit Logs  - myapp1 Logs
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

## Step-11: CleanUp - Sample Application
```t
# Delete Sample Application
kubectl delete -f 03-sample-app-test-container-insights
```

## Step-12: CleanUp - FluentBit
```t
# Delete FluentBit Optimized Configuration
kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml

# Create FluentBit ConfigMap (Update EKS Cluster Name in 02-cw-fluentbit-configmap.yaml)
kubectl delete -f 02-cwagent-container-insights/02-cw-fluentbit-configmap.yaml
```

## Step-13: CleanUp - Container Insights CloudWatch Agent
```t
# Delete the AWS CloudWatch agent as a DaemonSet 
kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml

# Delete a ConfigMap for the AWS CloudWatch agent 
kubectl delete -f 02-cwagent-container-insights/01-cw-agent-configmap.yaml

# Create a Service Account for AWS CloudWatch Agent
kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml

# Create Namespace for AWS CloudWatch Agent
kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
```

## Step-14: Delete Log Groups
- Delete log groups related to CloudWatch Agent and FluentBit
- /aws/containerinsights/<CLUSTER_NAME>/performance
- /aws/containerinsights/<CLUSTER_NAME>/application
- /aws/containerinsights/<CLUSTER_NAME>/dataplane
- /aws/containerinsights/<CLUSTER_NAME>/host


## Reference
- [AWS Cloud Watch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-EKS.html)
- [Troubleshooting Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights-troubleshooting.html)
- [Fluent Bit Setup](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html)
- [Reference Document](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html)
- [GIT REPO FOR DEPLOYMENT MODES](https://github.com/aws-samples/amazon-cloudwatch-container-insights/tree/master/k8s-deployment-manifest-templates/deployment-mode)