# Terraform Resource Meta-Argument lifecycle

## Step-01: Introduction
- lifecyle Meta-Argument block contains 3 arguments
  - create_before_destroy
  - prevent_destroy
  - ignore_changes
- Understand and implement each of these 3 things practically in a step by step manner  

## Step-02: lifecyle - create_before_destroy
- Default Behavior of a Resource: Destroy Resource & re-create Resource
- With Lifecycle Block we can change that using `create_before_destroy=true`
  - First new resource will get created
  - Second old resource will get destroyed
- **Add Lifecycle Block inside Resource Block to alter behavior**  
```t
  lifecycle {
    create_before_destroy = true
  }
```  
### Step-02-01: Observe without Lifecycle Block
```t
# Switch to Working Directory
cd v1-create_before_destroy

# Initialize Terraform
terraform init

# Validate Terraform Configuration Files
terraform validate

# Format Terraform Configuration Files
terraform fmt

# Generate Terraform Plan
terraform plan

# Create Resources
terraform apply -auto-approve

# Modify Resource Configuration
Change Availability Zone from us-east-1a to us-east-1b

# Apply Changes
terraform apply -auto-approve
Observation: 
1) First us-east-1a resource will be destroyed
2) Second us-east-1b resource will get
```
### Step-02-02: With Lifecycle Block
- Add Lifecycle block in the resource (Uncomment lifecycle block)
```t
# Generate Terraform Plan
terraform plan

# Apply Changes
terraform apply -auto-approve

# Modify Resource Configuration
Change Availability Zone from us-east-1b to us-east-1a

# Apply Changes
terraform apply -auto-approve
Observation: 
1) First us-east-1a resource will get created
2) Second us-east-1b resource will get deleted
```
### Step-02-03: Clean-Up Resources
```t
# Destroy Resources
terraform destroy -auto-approve

# Clean-Up 
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## Step-03: lifecycle - prevent_destroy
### Step-03-01: Introduction
- This meta-argument, when set to true, will cause Terraform to reject with an error any plan that would destroy the infrastructure object associated with the resource, as long as the argument remains present in the configuration.
- This can be used as a measure of safety against the accidental replacement of objects that may be costly to reproduce, such as database instances
- However, it will make certain configuration changes impossible to apply, and will prevent the use of the `terraform destroy` command once such objects are created, and so this option should be used `sparingly`.
- Since this argument must be present in configuration for the protection to apply, note that this setting does not prevent the remote object from being destroyed if the resource block were removed from configuration entirely: in that case, the `prevent_destroy` setting is removed along with it, and so Terraform will allow the destroy operation to succeed.
```t
  lifecycle {
    prevent_destroy = true # Default is false
  }
```
### Step-03-02: Execute Terraform Commands
```t
# Switch to Working Directory
cd v2-prevent_destroy

# Initialize Terraform
terraform init

# Validate Terraform Configuration Files
terraform validate

# Format Terraform Configuration Files
terraform fmt

# Generate Terraform Plan
terraform plan

# Create Resources
terraform apply -auto-approve

# Destroy Resource
terraform destroy 
Observation: 
Kalyans-MacBook-Pro:v2-prevent_destroy kdaida$ terraform destroy -auto-approve
Error: Instance cannot be destroyed
  on c2-ec2-instance.tf line 2:
   2: resource "aws_instance" "web" {
Resource aws_instance.web has lifecycle.prevent_destroy set, but the plan
calls for this resource to be destroyed. To avoid this error and continue with
the plan, either disable lifecycle.prevent_destroy or reduce the scope of the
plan using the -target flag.


# Remove/Comment Lifecycle block
- Remove or Comment lifecycle block and clean-up

# Destroy Resource after removing lifecycle block
terraform destroy

# Clean-Up
rm -rf .terraform*
rm -rf terraform.tfstate*
```


## Step-04: lifecyle - ignore_changes
### Step-04-01: Create an EC2 Changes, make manual changes and understand the behavior
- Create EC2 Instance
```t
# Switch to Working Directory
cd v3-ignore_changes

# Initialize Terraform
terraform init

# Terraform Validate
terraform validate

# Terraform Plan to Verify what it is going to create / update / destroy
terraform plan

# Terraform Apply to Create EC2 Instance
terraform apply 
```
### Step-04-02: Update the tag by going to AWS management console
- Add a new tag manually to EC2 Instance
- Try `terraform apply` now
- Terraform will find the difference in configuration on remote side when compare to local and tries to remove the manual change when we execute `terraform apply`
```t
# Add new tag manually
WebServer = Apache

# Terraform Plan to Verify what it is going to create / update / destroy
terraform plan

# Terraform Apply to Create EC2 Instance
terraform apply 
Observation: 
1) It will remove the changes which we manually added using AWS Management console
```

### Step-04-03: Add the lifecyle - ignore_changes block
- Enable the block in `c2-ec2-instance.tf`

```t
   lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
```
- Add new tags manually using AWS mgmt console for the EC2 Instance
```t
# Add new tag manually
WebServer = Apache2
ignorechanges = test1

# Terraform Plan to Verify what it is going to create / update / destroy
terraform plan

# Terraform Apply to Create EC2 Instance
terraform apply 
Observation: 
1) Manual changes should not be touched. They should be ignored by terraform
2) Verify the same on AWS management console

# Destroy Resource
terraform destroy -auto-approve

# Clean-Up
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## References
- [Resource Meat-Argument: Lifecycle](https://www.terraform.io/docs/language/meta-arguments/lifecycle.html)