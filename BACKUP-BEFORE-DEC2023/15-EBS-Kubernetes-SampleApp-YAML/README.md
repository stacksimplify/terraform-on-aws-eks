---
title: Demo on Kubernetes Storage Class, PVC and PV with YAML
description: Deploy UserMgmt WebApp on EKS Kubernetes with MySQL as Database
---

## Step-00: Introduction
- Understand k8s Storage Classes
- Understand k8s Persistent Volume Claims
- Understand k8s Persistent Volumes
- Understand k8s Persistent Volume Mounts
- Understand k8s Environment Variables
- **Usecase:** Deploy User Management Application on Kubernetes with EBS as storage for MySQL Pod

## Pre-requisite: Verify EKS Cluster and EBS CSI Driver already Installed
### Project-01: 01-ekscluster-terraform-manifests
```t
# Change Directroy
cd 15-EBS-Kubernetes-SampleApp-YAML/01-ekscluster-terraform-manifests

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
cd 15-EBS-Kubernetes-SampleApp-YAML/02-ebs-terraform-manifests

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

## Step-01: 01-storage-class.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: 
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer 
```
## Step-02: 02-persistent-volume-claim.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-mysql-pv-claim
spec: 
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources: 
    requests:
      storage: 4Gi
```
## Step-03: 03-UserManagement-ConfigMap.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: usermanagement-dbcreation-script
data: 
  mysql_usermgmt.sql: |-
    DROP DATABASE IF EXISTS webappdb;
    CREATE DATABASE webappdb; 
```

## Step-04: 04-mysql-deployment.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec: 
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate 
  template: 
    metadata: 
      labels: 
        app: mysql
    spec: 
      containers:
        - name: mysql
          image: mysql:5.6
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: dbpassword11
          ports:
            - containerPort: 3306
              name: mysql    
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql    
            - name: usermanagement-dbcreation-script
              mountPath: /docker-entrypoint-initdb.d #https://hub.docker.com/_/mysql Refer Initializing a fresh instance                                            
      volumes: 
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            claimName: ebs-mysql-pv-claim
        - name: usermanagement-dbcreation-script
          configMap:
            name: usermanagement-dbcreation-script
```

## Step-05: 05-mysql-clusterip-service.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: v1
kind: Service
metadata: 
  name: mysql
spec:
  selector:
    app: mysql 
  ports: 
    - port: 3306  
  clusterIP: None # This means we are going to use Pod IP    
```

## Step-06: 06-UserMgmtWebApp-Deployment.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata:
  name: usermgmt-webapp
  labels:
    app: usermgmt-webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: usermgmt-webapp
  template:  
    metadata:
      labels: 
        app: usermgmt-webapp
    spec:
      initContainers:
        - name: init-db
          image: busybox:1.31
          command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z mysql 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']      
      containers:
        - name: usermgmt-webapp
          image: stacksimplify/kube-usermgmt-webapp:1.0.0-MySQLDB
          imagePullPolicy: Always
          ports: 
            - containerPort: 8080           
          env:
            - name: DB_HOSTNAME
              value: "mysql"            
            - name: DB_PORT
              value: "3306"            
            - name: DB_NAME
              value: "webappdb"            
            - name: DB_USERNAME
              value: "root"            
            - name: DB_PASSWORD
              value: "dbpassword11"            
```

## Step-07: 07-UserMgmtWebApp-Classic-LoadBalancer-Service.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: usermgmt-webapp-clb-service
  labels: 
    app: usermgmt-webapp
spec: 
  type: LoadBalancer
  selector: 
    app: usermgmt-webapp
  ports: 
    - port: 80 # Service Port
      targetPort: 8080 # Container Port
```

## Step-08: 08-UserMgmtWebApp-Network-LoadBalancer.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: usermgmt-webapp-nlb-service
  labels: 
    app: usermgmt-webapp
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb    # To create Network Load Balancer
spec:
  type: LoadBalancer # Default - CLB
  selector:
    app: usermgmt-webapp
  ports: 
    - port: 80
      targetPort: 8080
```

## Step-09: 09-UserMgmtWebApp-NodePort-Service.yaml
- **Folder:** `15-EBS-Kubernetes-SampleApp-YAML/03-kube-manifests-UMS-WebApp`
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: usermgmt-webapp-nodeport-service
spec:
  type: NodePort # ClusterIp, # NodePort
  selector:
    app: usermgmt-webapp
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 8080 # Container Port
      nodePort: 31280 # Node Port
```

## Step-10: Deploy the UMS WebApp Application
```t
# Change Directory
cd 15-EBS-Kubernetes-SampleApp-YAML/

# Deploy Application using kubectl
kubectl apply -f 03-kube-manifests-UMS-WebApp
```

## Step-11: Verify Kubernetes Resources created
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

## Step-12: Connect to MySQL Database Pod
```t
# Connect to MySQL Database 
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -pdbpassword11

# Verify usermgmt schema got created which we provided in ConfigMap
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;

## Sample Output for above query
+--------+----------------------------+------------+-----------+--------------------------------------------------------------+--------+-----------+
| userid | email_address              | first_name | last_name | password                                                     | ssn    | user_name |
+--------+----------------------------+------------+-----------+--------------------------------------------------------------+--------+-----------+
|    101 | admin101@stacksimplify.com | Kalyan     | Reddy     | $2a$10$w.2Z0pQl9K5GOMVT.y2Jz.UW4Au7819nbzNh8nZIYhbnjCi6MG8Qu | ssn101 | admin101  |
+--------+----------------------------+------------+-----------+--------------------------------------------------------------+--------+-----------+
1 row in set (0.00 sec)
mysql> 

Observation:
1. If UserMgmt WebApp container successfully started, it will connect to Database and create the default user named admin101
Username: admin101
Password: password101
```
## Step-13: Access Sample Application
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



## Step-14: Node Port Service Port - Update Node Security Group
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


## Step-15: Access Sample using NodePort Service 
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

## Step-16: Remove Inbound Rule added  
- Go to Services -> Instances -> Find Private Node Group Instance -> Click on Security Tab
- Find the Security Group with name `eks-remoteAccess-`
- Go to the Security Group (Example Name: sg-027936abd2a182f76 - eks-remoteAccess-d6beab70-4407-dbc7-9d1f-80721415bd90)
- Remove the NodePort Rule which we added.

## Step-17: Clean-Up
```t
# Delete Kubernetes  Resources
kubectl delete -f kube-manifests-UMS-WebApp

# Verify Kubernetes Resources
kubectl get pods
kubectl get svc
```


