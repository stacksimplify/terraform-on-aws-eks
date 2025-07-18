# Control Costs with Sentinel Policies

## Step-01: Introduction
- We are going to learn the following in this section
- Sentinel Cost Control Policies
- Apply them for Ec2 Instance and verify pass and fail cases

## Step-02: Review Sentinel Cost Control Policies
### Step-02-01: less-than-100-month.sentinel
- This policy uses the tfrun import to check that the new cost delta is no more than \$100
- The decimal import is used for more accurate math when working with currency numbers.
```t
import "tfrun"
import "decimal"

delta_monthly_cost = decimal.new(tfrun.cost_estimate.delta_monthly_cost)

main = rule {
    delta_monthly_cost.less_than(100)
}
```

### Step-02-02: sentinel.hcl
```t
policy "less-than-100-month" {
  source  = "./less-than-100-month.sentinel"
  enforcement_level = "soft-mandatory"
}
```

## Step-03: Copy Sentinel Cost Control Policies to terraform-sentinel-policies git repo
- Copy folder `terraform-sentinel-cost-control-policies` to Local git repository `terraform-sentinel-policies`
- **Check-In code to Remote Repository**
```t
# GIT Status
git status

# Git Local Commit
git add .
git commit -am "Sentinel Cost Control Policies Added in new folder"

# Push to Remote Repository
git push

# Verify the same on Remote Repository
https://github.com/stacksimplify/terraform-sentinel-policies.git
```

## Step-04: Add new Sentinel Policy Set in Terraform Cloud
- Go to Terraform Cloud -> Organization (hcta-demo1) -> Settings -> Policy Sets
- Click on **Connect a new Policy Set**
- Use existing VCS connection from previous section **github-terraform-modules** which we created using OAuth App concept
- **Choose Repository:** terraform-sentinel-policies.git
- **Name:** terraform-sentinel-cost-control-policies
- **Description:** terraform sentinel cost control policies
- **Policies Path:** terraform-sentinel-cost-control-policies
- **Scope of Policies:** Policies enforced on selected workspaces
- **Workspaces:** terraform-cloud-demo1
- Click on **Connect Policy Set**

## Step-05: Review our first Terraform Cloud Workspace
- Go to Terraform Cloud -> Organization (hcta-demo1) -> workspace (terraform-cloud-demo1)
### Step-05-01: Configre Environment Variables in Terraform Cloud for AWS Provider
- [Setup AWS Access Keys for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
- Go to Organization (hcta-demo1) -> Workspace(terraform-cloud-demo1) -> Variables
- In environment variables, add the below two
- Configure AWS Access Key ID and Secret Access Key  
- **Environment Variable:** AWS_ACCESS_KEY_ID
  - Key: AWS_ACCESS_KEY_ID
  - Value: XXXXXXXXXXXXXXXXXXXXXX
- **Environment Variable:** AWS_SECRET_ACCESS_KEY
  - Key: AWS_SECRET_ACCESS_KEY
  - Value: YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

### Step-05-02: Pass Case: Queue Plan and Verify Cost Control Policies Applied
- Go to Organization (hcta-demo1) -> Workspace(terraform-cloud-demo1) 
- Queue Plan -> Cost-Control-Test-1-Pass-case
- Verify the following
  - Plan
  - Cost Estimate
  - Policy Check:  Policy check should pass
- Finally, Disacrd the Run

### Step-05-03: Fail Case: Queue Plan and Verify Cost Control Policies Applied
- Go to Organization (hcta-demo1) -> Workspace(terraform-cloud-demo1) -> Variables
- Update `instance_type` Variable
```t
# Before Change
instance_type = t3.micro

# After Change
instance_type = t3.2xlarge
```
- Queue Plan -> Cost-Control-Test-1-Fail-case
- Verify the following
  - Plan
  - Cost Estimate
  - Policy Check:  Policy check should fail
- Finally, Disacrd the Run
- Roll back `instance_type` to `t3.micro`

## Step-06: Sentinel Policies  - Conclusion
- We can create multiple sentinel policies in different folder paths in single github repository like `terraform-sentinel-policies`
- We can apply few of them at `Terraform Organization` level and few of them at `Terraform Workspace` level.
- Very flexible and conveniet.