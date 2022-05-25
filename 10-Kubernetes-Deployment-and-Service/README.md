---
title: Kubernetes Deployment and Services
description: Deploy sample application to EKS Cluster
---
## Step-01: Introduction
- Create k8s Deployment manifest using YAML
- Create k8s NodePort Service manifest using YAML
- Create k8s Load Balancer Service manifest using YAML which creates AWS Classic Load Balancer
- Create k8s Load Balancer Service manifest using YAML with annotations concept which creates AWS Network Load Balancer

## Pre-requisite-1: YAML Quick Reference
- [YAML Basics will part of Docker and Kubernetes Fundamentals](https://github.com/stacksimplify/kubernetes-fundamentals/tree/master/06-YAML-Basics)
```t
# YAML in simple terms
## --- Separate YAML Document
## Key Value Pairs
## Dictionary
## Lists
## Ansible has very good examples explaining YAML Syntax:  https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html
```
- [For additional reference about YAML](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html)

## Pre-requisite-2: Configure kubeconfig for kubectl
```t
# Configure kubeconfig for kubectl
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name hr-stag-eksdemo1

# List Worker Nodes
kubectl get nodes
kubectl get nodes -o wide

# Verify Services
kubectl get svc
```

## Step-02: Review Sample Application - Deployment Manifest
- **File:** `kube-manifests/01-Deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata: #Dictionary
  name: myapp1-deployment
spec: # Dictionary
  replicas: 2
  selector:
    matchLabels:
      app: myapp1
  template:  
    metadata: # Dictionary
      name: myapp1-pod
      labels: # Dictionary
        app: myapp1  # Key value pairs
    spec:
      containers: # List
        - name: myapp1-container
          image: stacksimplify/kubenginx:1.0.0
          ports: 
            - containerPort: 80  
    
```

## Step-03: Review Sample Application - Load Balancer Service Manifest
- **File:** `kube-manifests/02-CLB-LoadBalancer-Service.yaml`
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-lb-service
spec:
  type: LoadBalancer # ClusterIp, # NodePort
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
```

## Step-04: Review Sample Application - Node Port Service Manifest
- **File:** `kube-manifests/03-NodePort-Service.yaml`
- Why do we need NodePort Service if we already have Load Balancer Service created as part of `02-LoadBalancer-Service.yaml` ?
   - `LoadBalancer Service` creates Classic Load Balancer
   - AWS will be retiring the EC2-Classic network on August 15, 2022.
   - As part of that, if AWS retires Classic Load Balancer, then we should have an option to test the things in other way.
   - For that purpose, we will use the NodePort service as a backup option. 
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-nodeport-service
spec:
  type: NodePort # ClusterIp, # NodePort
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
      nodePort: 31280 # Node Port
```
## Step-05:Review Sample Application - AWS Network Load Balancer Service Manifest
- **File:** `kube-manifests/04-NLB-LoadBalancer-Service.yaml`
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-lb-service-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb    # To create Network Load Balancer  
spec:
  type: LoadBalancer # ClusterIp, # NodePort
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
```
## Step-06: Deploy Sample Application in EKS k8s Cluster and Verify
```t
# Deploy Sample Application
kubectl apply -f kube-manifests/

# List Pods
kubectl get pods -o wide
Observation: 
1. Two app pods in Public Node Groups should be displayed


# List Services
kubectl get svc

# Sample Output
Kalyans-Mac-mini:09-Kubernetes-Deployment-and-Service kalyanreddy$ kubectl get svc
NAME                      TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)        AGE
kubernetes                ClusterIP      172.20.0.1       <none>                                                                          443/TCP        3h42m
myapp1-lb-service         LoadBalancer   172.20.147.138   ab64af75f852f45e5ad7bf19a8399135-1635652031.us-east-1.elb.amazonaws.com         80:32648/TCP   25s
myapp1-lb-service-nlb     LoadBalancer   172.20.58.57     af738ec8a524e4288bf83ee61962a30f-55388eedfc94fa0e.elb.us-east-1.amazonaws.com   80:32288/TCP   24s
myapp1-nodeport-service   NodePort       172.20.246.38    <none>                                                                          80:31280/TCP   25s
Kalyans-Mac-mini:09-Kubernetes-Deployment-and-Service kalyanreddy$ 

```

## Step-07: Verify Load Balancer
1. Go to Services -> EC2 -> Load Balancing -> Load Balancers
2. Verify Classic Load Balancer -> Verify Tabs
   - Description: Make a note of LB DNS Name
   - Instances: Status of Instances should be in state "InService"
   - Health Checks
   - Listeners
   - Monitoring
4. Verify Network Load Balancer -> Verify Tabs
   - Description: Make a note of LB DNS Name
   - Listeners
   - WAIT FOR NLB TO BE IN ACTIVE STATE. IT WILL TAKE SOMETIME TO BE ACTIVE.   
```t
# List Services
kubectl get svc

# Access Sample Application on Browser
http://<CLB-LB-DNS-NAME>
http://ab64af75f852f45e5ad7bf19a8399135-1635652031.us-east-1.elb.amazonaws.com

http://<NLB-LB-DNS-NAME>
http://af738ec8a524e4288bf83ee61962a30f-55388eedfc94fa0e.elb.us-east-1.amazonaws.com
```   

## Step-08: Node Port Service Port - Update Node Security Group
- **Important Note:** This is not a recommended option to update the Node Security group to open ports to internet, but just for learning and testing we are doing this. 
- Go to Services -> Instances -> Find Public Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Add an additional Inbound Rule
   - **Type:** Custom TCP
   - **Protocol:** TCP
   - **Port range:** 31280
   - **Source:** Anywhere (0.0.0.0/0)
   - **Description:** NodePort Rule
- Click on **Save rules**

## Step-09: Verify by accessing the Sample Application using NodePort Service
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

## Step-10: Remove Inbound Rule added 
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Remove the NodePort Rule which we added.

## Step-11: Clean-Up
```t
# Undeploy Application
kubectl delete -f kube-manifests/
```



