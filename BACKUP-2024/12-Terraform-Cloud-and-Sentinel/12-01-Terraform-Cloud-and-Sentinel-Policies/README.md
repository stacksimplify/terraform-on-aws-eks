# Terraform Cloud and Sentinel Policies

## Step-01: Introduction
- We are going to learn the following in this section
- Enable Trial plan for 30 days on hcta-demo1 organization which will enable **Team & Governance** features of Terraform Cloud
- Implement CLI-Driven workflow using Terraform Cloud for a S3 bucket resource
- Understand about two sentinel policies
  - check-terraform-version.sentinel
  - restrict-s3-buckets.sentinel
- Create Github repository for Sentinel Policies to use them as Policy Sets in Terraform Cloud
- Create Policy Sets in Terraform Cloud and Apply to demo workspace
- Test if sentinel policies applied and worked successfully.  


## Step-02: Review Terraform manifests
- **c1-versions.tf**
  - We are going to add Terraform Cloud as backend and implement CLI-Driven workflow on Terraform Cloud for this usecase for our learning. 
- **c2-variables.tf**
  - Bucket Name and Tags have default values and due to unique constraint for s3 bucket names, please use different bucket name when you are implementing it. 
- **c3-s3bucket.tf**
  - We are using this S3 bucket resource from **10-02-Terraform-Build-a-Module/v2-host-static-website-on-s3-using-terraform-manifests**.
  - In addition, we are going to add new resource named **aws_s3_bucket_object**, which will upload the `static-files/index.html` automatically during `terraform apply`
```t
resource "aws_s3_bucket_object" "bucket" {
  acl          = "public-read"
  key          = "index.html"
  bucket       = aws_s3_bucket.s3_bucket.id
  content      = file("${path.module}/static-files/index.html")
  content_type = "text/html"
}
```  
- **c4-outputs.tf**
  - We are going to have only S3 website endpoint as output with and without http appended. 

## Step-03: Create CLI-Driven Workspace on Terraform Cloud
### Step-03-01: Enable Trial plan in hcta-demo1 organization
- Login to Terraform Cloud
- Goto -> Organizations (hcta-demo1) -> Settings -> Plan & Billing
- Click on **Change Plan**
- Select **Trial Plan: Try out the Team & Governance plan features for 30 days**
- Click on **Start Free Trial**

### Step-03-02: Create CLI-Driven Workspace in organization hcta-demo1
- Login to [Terraform Cloud](https://app.terraform.io/)
- Select Organization -> hcta-demo1
- Click on **New Workspace**
- **Choose your workflow:** CLI-Driven Workflow
- **Workspace Name:** sentinel-demo1
- Click on **Create Workspace**

### Step-03-03: Update c1-versions.tf with Terraform Backend in Terraform Block
```t
terraform {
  backend "remote" {
    organization = "hcta-demo1"

    workspaces {
      name = "sentinel-demo1"
    }
  }
}
```
### Step-03-04: Configre Environment Variables in Terraform Cloud for AWS Provider
- [Setup AWS Access Keys for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
- Go to Organization (hcta-demo1) -> Workspace(sentinel-demo1) -> Variables
- In environment variables, add the below two
- Configure AWS Access Key ID and Secret Access Key  
- **Environment Variable:** AWS_ACCESS_KEY_ID
  - Key: AWS_ACCESS_KEY_ID
  - Value: XXXXXXXXXXXXXXXXXXXXXX
- **Environment Variable:** AWS_SECRET_ACCESS_KEY
  - Key: AWS_SECRET_ACCESS_KEY
  - Value: YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY


### Step-03-05: Execute Terraform Commands
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


# Terrafrom Initialize
terraform init

# Terraform Plan
terraform plan
Observation: 
1) Cost Estimation with this bucket should be displayed as we enabled the trial plan for 30 days on this organization (hcta-demo1)

# Terraform Apply
terraform apply -auto-approve

# Verify 
1) Access S3 static website and test
2) Review the plan and apply logs in Terraform Cloud respective workspace
```

## Step-04: Review Sentinel Policies
- [Sentinel Documentation](https://www.terraform.io/docs/cloud/sentinel/index.html)
### Step-04-01: check-terraform-version.sentinel
```t
import "tfplan/v2" as tfplan
import "strings"

v = strings.split(tfplan.terraform_version, ".")
version_major = int(v[1])
version_minor = int(v[2])

main = rule {
    #version_major is 14 and version_minor >= 1
    version_major >= 14
}
```

### Step-04-02: restrict-s3-buckets.sentinel
```t
import "tfplan/v2" as tfplan

s3_buckets = filter tfplan.resource_changes as _, rc {
  rc.type is "aws_s3_bucket" and
  (rc.change.actions contains "create" or rc.change.actions is ["update"])
}

required_tags = [
    "Terraform",
    "Environment",
]

allowed_acls = [
    "private",
    "public-read",
]

bucket_tags = rule {
    all s3_buckets as _, instances {
        all required_tags as rt {
        instances.change.after.tags contains rt
        }
    }
}

acl_allowed = rule {
    all s3_buckets as _, buckets {
    buckets.change.after.acl in allowed_acls
    }
}

main = rule {
    (bucket_tags and acl_allowed) else false
}

```

### Step-04-03: sentinel.hcl
```t
policy "check-terraform-version" {
    source            = "./check-terraform-version.sentinel"        
    enforcement_level = "hard-mandatory"
}

policy "restrict-s3-buckets" {
    source            = "./restrict-s3-buckets.sentinel"           
    enforcement_level = "soft-mandatory"
}
```
## Step-05: Create Github Repository for Sentinel Policies (Policy Sets)
### Step-05-01: Create new github Repository
- **URL:** github.com
- Click on **Create a new repository**
- **Repository Name:** terraform-sentinel-policies
- **Description:** Terraform Cloud and Sentinel Policies Demo 
- **Repo Type:** Public / Private
- **Initialize this repository with:**
- **CHECK** - Add a README file
- **CHECK** - Add .gitignore 
- **Select .gitignore Template:** Terraform
- **CHECK** - Choose a license  (Optional)
- **Select License:** Apache 2.0 License
- Click on **Create repository**

## Step-05-02: Clone Github Repository to Local Desktop
```t
# Clone Github Repo
git clone https://github.com/<YOUR_GITHUB_ID>/<YOUR_REPO>.git
git clone https://github.com/stacksimplify/terraform-sentinel-policies.git
```

## Step-05-03: Copy files from terraform-sentinel-policies folder to local repo & Check-In Code
- List of files to be copied
  - check-terraform-version.sentinel
  - restrict-s3-buckets.sentinel
  - sentinel.hcl
- **Source Location:** Section-12-01 - Inside `terraform-sentinel-policies` folder
- **Destination Location:** Newly cloned github repository folder in your local desktop `terraform-sentinel-policies`
- **Check-In code to Remote Repository**
```t
# GIT Status
git status

# Git Local Commit
git add .
git commit -am "Sentinel Policies First Commit"

# Push to Remote Repository
git push

# Verify the same on Remote Repository
https://github.com/stacksimplify/terraform-sentinel-policies.git
```

## Step-06: Create Policy Sets in Terraform Cloud
- Go to Terraform Cloud -> Organization (hcta-demo1) -> Settings -> Policy Sets
- Click on **Connect a new Policy Set**
- Use existing VCS connection from previous section **github-terraform-modules** which we created using OAuth App concept
- **Choose Repository:** terraform-sentinel-policies.git
- **Description:** Demo Sentinel Policies
- **Scope of Policies:** Policies enforced on selected workspaces
- **Workspaces:** sentinel-demo
- Click on **Connect Policy Set**

## Step-07: Update static-files/index.html in terraform-manifests
- Update static-files/index.html in terraform-manifests
```t
# Terraform Plan
terraform plan
Observation: 
1) Changes related to index.html should be printed in terraform plan
2) Cost Estimation with this bucket should be displayed as we enabled the trial plan for 30 days on this organization (hcta-demo1)
3) Sentinel policy execution should be displayed

# Terraform Apply
terraform apply -auto-approve
Observation: 
1) Changes related to index.html should be printed in terraform apply
2) Cost Estimation with this bucket should be displayed as we enabled the trial plan for 30 days on this organization (hcta-demo1)
3) Sentinel policy execution should be displayed

# Verify in Terraform Cloud
Observations:
1) Cost Estimation should be displayed
2) Also Sentinel Policy check should be displayed
```

## Step-08: Verify Sentinel Policy Failure Scenario
### Step-08-01: c2-variables.tf
- Update required tags to different value
```t
# Before Change
variable "tags" {
  description = "Tages to set on the bucket"
  type        = map(string)
  default     = {
    Terraform = "true"
    Environment = "dev"
    newtag1 = "tag1"
    newtag2 = "tag2"
  }
}

# After Change
variable "tags" {
  description = "Tages to set on the bucket"
  type        = map(string)
  default     = {
    abcdef = "true"  # modified one required tag so that sentinel policy restrict-se-buckets.sentinel will fail
    Environment = "dev"
    newtag1 = "tag1"
    newtag2 = "tag2"
  }
}
```
### Step-08-02: Execute Terraform Commands
```t
# Terraform Plan
terraform plan
Observation: 
1) Changes related to tag should be printed in terraform plan
2) Sentinel policy execution should report a failure for policy restrict-s3-buckets.sentinel

# Terraform Apply
terraform apply -auto-approve
Observation: 
1) Changes related to tag should be printed in terraform apply
2) Sentinel policy execution should report a failure for policy restrict-s3-buckets.sentinel

# Verify in Terraform Cloud
Observation: 
1) Sentinel policy execution will fail and terraform apply will not be executed
```

## Step-09: Clean-Up & Destroy
```t
# Terraform Destroy
terraform destroy -auto-approve

# Clean-Up files
rm -rf .terraform*
```

## References 
- [Terraform & Sentinel](https://www.terraform.io/docs/cloud/sentinel/index.html)
- [Example Sentinel Policies](https://www.terraform.io/docs/cloud/sentinel/examples.html)
- [Sentinel Foundational Policies](https://github.com/hashicorp/terraform-foundational-policies-library)
- [Sentinel Enforcement Levels](https://docs.hashicorp.com/sentinel/concepts/enforcement-levels)
