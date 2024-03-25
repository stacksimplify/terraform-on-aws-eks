# Terraform Cloud & Github Integration

## Step-01: Introduction
- Create Github Repository on github.com
- Clone Github Repository to local desktop
- Copy & Check-In Terraform Configurations in to Github Repository
- Create Terraform Cloud Account
- Create Organization
- Create Workspace by integrating with Github.com Git Repo we recently created
- Learn about Workspace related Queue Plan, Runs, States, Variables and Settings


## Step-02: Create new github Repository
- **URL:** github.com
- Click on **Create a new repository**
- **Repository Name:** terraform-cloud-demo1
- **Description:** Terraform Cloud Demo 
- **Repo Type:** Public / Private
- **Initialize this repository with:**
- **CHECK** - Add a README file
- **CHECK** - Add .gitignore 
- **Select .gitignore Template:** Terraform
- **CHECK** - Choose a license
- **Select License:** Apache 2.0 License
- Click on **Create repository**

## Step-03: Review .gitignore created for Terraform
- Review .gitignore created for Terraform projects

## Step-04: Clone Github Repository to Local Desktop
```t
# Clone Github Repo
git clone https://github.com/<YOUR_GITHUB_ID>/<YOUR_REPO>.git
git clone https://github.com/stacksimplify/terraform-cloud-demo1.git
```

## Step-05: Copy files from terraform-manifests to local repo & Check-In Code
- List of files to be copied
  - apache-install.sh
  - c1-versions.tf
  - c2-variables.tf
  - c3-security-groups.tf
  - c4-ec2-instance.tf
  - c5-outputs.tf
  - c6-ami-datasource.tf
- Source Location: Section-11-01 - Inside terraform-manifests folder
- Destination Location: Newly cloned github repository folder in your local desktop `terraform-cloud-demo1`
- Verify locally before commiting to GIT Repository
```t
# Terraform Init
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan
```
- Check-In code to Remote Repository
```t
# GIT Status
git status

# Git Local Commit
git add .
git commit -am "TF Files First Commit"

# Push to Remote Repository
git push

# Verify the same on Remote Repository
https://github.com/stacksimplify/terraform-cloud-demo1.git
```

## Step-06: Sign-Up for Terraform Cloud - Free Account & Login
- **SignUp URL:** https://app.terraform.io/signup/account
- **Username:**
- **Email:**
- **Password:** 
- **Login URL:** https://app.terraform.io

## Step-07: Create Organization 
- **Organization Name:** hcta-demo1
- **Email Address:** stacksimplify@gmail.com
- Click on **Create Organization**

## Step-08: Create New Workspace
- Get in to newly created Organization
- Click on **New Workspace**
- **Choose your workflow:** V
  - Version Control Workflow
- **Connect to VCS**
  - **Connect to a version control provider:** github.com
  - NEW WINDOW: **Authorize Terraform Cloud:** Click on **Authorize Terraform Cloud Button**
  - NEW WINDOW: **Install Terraform Cloud**
  - **Select radio button:** Only select repositories
  - **Selected 1 Repository:** stacksimplify/terraform-cloud-demo1
  - Click on **Install**
- **Choose a Repository**
  - stacksimplify/terraform-cloud-demo1
- **Configure Settings**
  - **Workspace Name:** terraform-cloud-demo1 (Whatever populated automically leave to defaults) 
  - **Advanced Settings:** leave to defaults 
- Click on **Create Workspace**  
- You should see this message `Configuration uploaded successfully`


## Step-09: Configure Variables
- **Variable:** aws_region
  - key: aws_region
  - value: us-east-1
- **Variable:** instance_type
  - key: instance_type
  - value: t3.micro

## Step-10: Configre Environment Variables
- [Setup AWS Access Keys for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
- Configure AWS Access Key ID and Secret Access Key  
- **Environment Variable:** AWS_ACCESS_KEY_ID
  - Key: AWS_ACCESS_KEY_ID
  - Value: XXXXXXXXXXXXXXXXXXXXXX
- **Environment Variable:** AWS_SECRET_ACCESS_KEY
  - Key: AWS_SECRET_ACCESS_KEY
  - Value: YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

## Step-11: Click on Queue Plan
- Go to Workspace -> Runs -> Queue Plan
- Review the plan generated in **Full Screen**
- **Add Comment:** First Run
- Click on **Confirm & Apply**
- **Add Comment:** First Run Approved
- Click on **Confirm Plan**
- Review Apply log output in **Full Screen**
- **Add Comment:** Successfully Provisioned, Verified in AWS

## Step-12: Review Terraform State
- Go to Workspace -> States
- Review the state file

## Step-13: Change Number of Instance
- Go to Local Desktop -> Local Repo -> c4-ec2-instance.tf -> Change count from 1 to 2
```t
# Change c4-ec2-instance.tf
count = 2

# GIT Status
git status

# Git Local Commit
git add .
git commit -am "Changed EC2 Instances from 1 to 2"

# Push to Remote Repository
git push

# Verify Terraform Cloud
Go to Workspace -> Runs 
Observation: 
1) New plan should be queued ->  Click on Current Plan and review logs in Full Screen
2) Click on **Confirm and Apply**
3) Add Comment: Approved for new EC2 Instance and Click on **Confirm Plan**
4) Verify Apply Logs in Full Screen
5) Review the update state in  Workspace -> States
6) Verify if new EC2 Instance got created
```

## Step-14: Review Workpace Settings
- Goto -> Workspace -> Settings
  - General Settings
  - Locking
  - Notifications
  - Run Triggers
  - SSH Key
  - Version Control

## Step-15: Destruction and Deletion
- Goto -> Workspace -> Settings -> Destruction and Deletion
- click on **Queue Destroy Plan** to delete the resources on cloud 
- Goto -> Workspac -> Runs -> Click on **Confirm & Apply**
- **Add Comment:** Approved for Deletion

