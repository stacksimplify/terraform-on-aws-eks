# Terraform Cloud - CLI-Driven Workflow

## Step-01: Introduction
- Learn and practically implement `CLI-Driven Workflow` in Terraform Cloud

## Step-02: Review Terraform Configuration Files
- c1-versions.tf
- c2-variables.tf
- c3-s3bucket.tf
- c4-outputs.tf

## Step-03: Create Workspace with CLI Driven Workflow
- Login to [Terraform Cloud](https://app.terraform.io/)
- Select Organization -> hcta-demo1
- Click on **New Workspace**
- **Choose your workflow:** CLI-Driven Workflow
- **Workspace Name:** cli-driven-demo
- Click on **Create Workspace**

## Step-04: Add backend block in Terraform Settings c1-versions.tf
```t
terraform {
  backend "remote" {
    organization = "hcta-demo1"

    workspaces {
      name = "cli-driven-demo"
    }
  }
}
```

## Step-05: Execute Terraform Commands
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
1. Should pass and download modules and providers

# Terraform Validate
terraform validate

# Terraform Format
terraform fmt

# Terraform Plan
terraform plan
Observation: Should fail with error due to AWS Provider credential configuration not done on Terraform Cloud for this respective workspace
```

## Step-06: Configre Environment Variables
- [Setup AWS Access Keys for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
- Go to Organization (hcta-demo1) -> Workspace(cli-driven-demo) -> Variables
- In environment variables, add the below two
- Configure AWS Access Key ID and Secret Access Key  
- **Environment Variable:** AWS_ACCESS_KEY_ID
  - Key: AWS_ACCESS_KEY_ID
  - Value: XXXXXXXXXXXXXXXXXXXXXX
- **Environment Variable:** AWS_SECRET_ACCESS_KEY
  - Key: AWS_SECRET_ACCESS_KEY
  - Value: YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY


## Step-07: Execute Terraform Commands
```t
# Terraform Plan
terraform plan
Observation: 
1) Terraform plan should pass now. 
2) Discuss about cost estimation and trial plan for 30 days

# Terraform Apply
terraform apply 

# Verify 
1. Bucket has static website hosting enabled
2. Bucket has public read access enabled using policy
3. Bucket has "Block all public access" unchecked
```


### Step-08: Upload index.html and test
```t
# Endpoint Format
http://example-bucket.s3-website.Region.amazonaws.com/

# Replace Values (Bucket Name, Region)
http://mybucket-1051.s3-website.us-east-1.amazonaws.com/
```

## Step-09: Verify the following
- Select Organization -> hcta-demo1
- Click on **New Workspace**
- **Choose your workflow:** CLI-Driven Workflow
- **Workspace Name:** cli-driven-demo
- Runs
- States

## Step-10: Make changes and execute Terraform commands
- Update `c2-variables.tf` with new tag
- Execute Terraform Commands
```t
# Terraform Plan
terraform plan
Observation: 
1) Verify Terraform cloud Runs tab
2) We should see the runs are taking place for changes in Terraform cloud

# Terraform Apply
terraform apply -auto-approve
```
### Step-11: Destroy and Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Terraform files 
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## Additional References
- [CLI Configuration File](https://www.terraform.io/docs/cli/config/config-file.html#credentials)