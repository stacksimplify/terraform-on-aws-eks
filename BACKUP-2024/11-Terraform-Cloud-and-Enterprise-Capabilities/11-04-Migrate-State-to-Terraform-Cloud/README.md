# Migrate State to Terraform Cloud

## Step-01: Introduction
- We are going to migrate State to Terraform Cloud

## Step-02: Review Terraform Manifests
- c1-versions.tf
- c2-variables.tf: 
  - **Important Note:** No default values provided for variables 
- c3-security-groups.tf
- c4-ec2-instance.tf
- c5-outputs.tf
- c6-ami-datasource.tf
- apache-install.sh


## Step-03: Execute Terraform Commands (First provision using local backend)
- First provision infra using local backend
- `terraform.tfstate` file will be created in local working directory
- In next steps, migrate it to Terraform Cloud
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-04: Review your local state file
-  Review your local `terraform.tfstate` file once


## Step-05: Update remote backend in c1-versions.tf Terraform Block
### Step-05-01: Create New Workspace with CLI-Driven workflow
- Create New workspace with CLI-Driven workflow
- Login to [Terraform Cloud](https://app.terraform.io/)
- Select Organization -> hcta-demo1
- Click on **New Workspace**
- **Choose your workflow:** CLI-Driven Workflow
- **Workspace Name:** state-migration-demo
- Click on **Create Workspace**

### Step-05-02: Update remote backend in c1-versions.tf Terraform Block
```t
# Template
  backend "remote" {
    hostname      = "app.terraform.io"
    organization  = "<YOUR-ORG-NAME>"

    workspaces {
      name = "<SOME-NAME>"
    }
  }

# Replace Values
  backend "remote" {
    hostname      = "app.terraform.io"
    organization  = "hcta-demo1"  # Organization should already exists in Terraform Cloud

    workspaces {
      name = "state-migration-demo" 
      # Two cases: 
      # Case-1: If workspace already exists, should not have any state files in states tab
      # Case-2: If workspace not exists, during migration it will get created
    }
  }
```
- **Case-2 above for workspaces is failing with this error**
```
Kalyans-MacBook-Pro:terraform-manifests kdaida$ terraform init
Initializing the backend...
Error: Error looking up workspace
Workspace read failed: resource not found
Kalyans-MacBook-Pro:terraform-manifests kdaida$
```

## Step-06: Migrate State file to Terraform Cloud and Verify
```t
# Terraform Login
terraform login
Observation: 
1) Should see message |Success! Terraform has obtained and saved an API token.|
2) Verify Terraform credentials file
cat /Users/<YOUR_USER>/.terraform.d/credentials.tfrc.json
cat /Users/kdaida/.terraform.d/credentials.tfrc.json
Additional Reference:
https://www.terraform.io/docs/cli/config/config-file.html#credentials-1
https://www.terraform.io/docs/cloud/registry/using.html#configuration

# Terraform Initialize
terraform init
Observation: 
1) During reinitialization, Terraform presents a prompt saying that it will copy the state file to the new backend. 
2) Enter yes and Terraform will migrate the state from your local machine to Terraform Cloud.

# Verify in Terraform Cloud
1) New workspace should be created with name "state-migration-demo"
2) Verify "states" tab in workspace, we should find the state file
```

## Step-07: Add Variables & AWS Credentials in Environment Variables
### Step-07-01: Add Variables
```t
aws_region = us-east-1
instance_type = t3.micro
```
### Step-07-02: Configre Environment Variables
- [Setup AWS Access Keys for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
- Go to Organization (hcta-demo1) -> Workspace(state-migration-demo) -> Variables
- In environment variables, add the below two
- Configure AWS Access Key ID and Secret Access Key  
- **Environment Variable:** AWS_ACCESS_KEY_ID
  - Key: AWS_ACCESS_KEY_ID
  - Value: XXXXXXXXXXXXXXXXXXXXXX
- **Environment Variable:** AWS_SECRET_ACCESS_KEY
  - Key: AWS_SECRET_ACCESS_KEY
  - Value: YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
 
## Step-08: Delete local terraform.tfstate
- First take backup and put it safe and delete it
```t
# Take backup
cp terraform.tfstate terraform.tfstate_local_before_migrate_to_TF_Cloud

# Delete
rm terraform.tfstate
``` 

## Step-09: Apply a new run from CLI
- Make a change and do  `terraform apply`
```t
# Change Instances from 1 to 2 (c4-ec2-instance.tf)
count = 2

# Terraform Apply
terraform apply 

# Verify in Terraform Cloud
1) Verify in Runs Tab in TF Cloud
2) Verify States Tab in TF Cloud
```

## Step-10: Destroy & Clean-Up
-  Destroy Resources from cloud this time instead of `terraform destroy` command
- Go to Organization (hcta-demo1) -> Workspace(state-migration-demo) -> Settings -> Destruction and Deletion
- Click on **Queue Destroy Plan**
```t
# Clean-Up files
rm -rf .terraform*
rm -rf terraform.tfstate*
```
