# Terraform Input Variables

## Step-00: Introduction
- **v1:** Input Variables - Basics
- **v2:** Provide Input Variables when prompted during terraform plan or apply
- **v3:** Override default variable values using CLI argument `-var` 
- **v4:** Override default variable values using Environment Variables
- **v5:** Provide Input Variables using `terraform.tfvars` files
- **v6:** Provide Input Variables using `<any-name>.tfvars` file with CLI 
argument `-var-file`
- **v7:** Provide Input Variables using `auto.tfvars` files
- **v8-01:** Implement complex type constructors like `list` 
- **v8-02:** Implement complex type constructors like `maps`
- **v9:** Implement Custom Validation Rules in Variables
- **v10:** Protect Sensitive Input Variables
- **v11:** Understand about `File` function

## Pre-requisite
- Create a new EC2 Key pair with name as `terraform-key`
- In all the templates listed below V1 to V12, we will be using `key_name      = "terraform-key"` incase if you want to login to EC2 Instance you can use this key


## Step-01: Input Variables Basics 
- **Reference Sub folder:** v1-Input-Variables-Basic
- Create / Review the terraform manifests
  - c1-versions.tf
  - c2-variables.tf
  - c3-security-groups.tf
  - c4-ec2-instance.tf
- We are going to define `c3-variables.tf` and define the below listed variables
  - aws_region is a variable of type `string`
  - ec2_ami_id is a variable of type `string`
  - ec2_instance_count is a variable of type `number`
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan

# Create Resources
terraform apply

# Access Application
http://<Public-IP-Address>

# Clean-Up
terraform destroy -auto-approve
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## Step-02: Input Variables Assign When Prompted
- **Reference Sub folder:** v2-Input-Variables-Assign-when-prompted
- Add a new variable in `variables.tf` named `ec2_instance_type` without any default value. 
- As the variable doesn't have any default value when you execute `terraform plan` or `terraform apply` it will prompt for the variable. 

```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan
```

## Step-03: Input Variables Override default value with cli argument `-var`
- **Reference Sub folder:** v3-Input-Variables-Override-default-with-cli
- We are going to override the default values defined in `variables.tf` by providing new values using the `-var` argument using CLI
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Option-1 (Always provide -var for both plan and apply)
# Review the terraform plan
terraform plan -var="ec2_instance_type=t3.large" -var="ec2_instance_count=1"

# Create Resources (optional)
terraform apply -var="ec2_instance_type=t3.large" -var="ec2_instance_count=1"

# Option-2 (Generate plan file with -var and use that with apply)
# Generate Terraform plan file
terraform plan -var="ec2_instance_type=t3.large" -var="ec2_instance_count=1" -out v3out.plan

# Create / Deploy Terraform Resources using Plan file
terraform apply v3out.plan 
```

## Step-04: Input Variables Override with Environment Variables
- **Reference Sub folder:** v4-Input-Variables-Override-with-Environment-Variables
- Set environment variables and execute `terraform plan` to see if it overrides default values 
```t
# Sample
export TF_VAR_variable_name=value

# SET Environment Variables
export TF_VAR_ec2_instance_count=1
export TF_VAR_ec2_instance_type=t3.large
echo $TF_VAR_ec2_instance_count, $TF_VAR_ec2_instance_type

# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan

# UNSET Environment Variables after demo
unset TF_VAR_ec2_instance_count
unset TF_VAR_ec2_instance_type
echo $TF_VAR_ec2_instance_count, $TF_VAR_ec2_instance_type
```

## Step-05: Assign Input Variables from terraform.tfvars
- **Reference Sub folder:** v5-Input-Variables-Assign-with-terraform-tfvars
- Create a file named `terraform.tfvars` and define variables
- If the file name is `terraform.tfvars`, terraform will auto-load the variables present in this file by overriding the `default` values in `variables.tf`
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan

# Create Resources
terraform apply

# Access Application
http://<Elastic-IP-Address>
```

## Step-06: Assign Input Variables with -var-file argument
- **Reference Sub folder:** v6-Input-Variables-Assign-with-tfvars-var-file
- If we plan to use different names for  `.tfvars` files, then we need to explicitly provide the argument `-var-file` during the `terraform plan or apply`
- We will use following things in this example
  - **c2-variables.tf:** aws_region variable will be picked with default value
  - **terraform.tfvars:** ec2_instance_count variable will be picked from this file
  - **web.tfvars:** ec2_instance_type variable will be picked from this file
  - **app.tfvars:** ec2_instance_type variable will be picked from this file
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan -var-file="web.tfvars"
terraform plan -var-file="app.tfvars"
```

## Step-07: Auto load input variables with .auto.tfvars files
- **Reference Sub folder:** v7-Input-Variables-Assign-with-auto-tfvars
- We will create a file with extension as `.auto.tfvars`. 
- With this extension, whatever may be the file name, the variables inside these files will be auto loaded during `terraform plan or apply`
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan 
```
## Step-08: Implement complex type cosntructors like `list` and `maps`
- **Reference Sub folder:** v8-Input-Variables-Lists-Maps
- [Type Constraints](https://www.terraform.io/docs/language/expressions/types.html)
### Step-08-01: Implement Vairable Type as List
- **list (or tuple):** a sequence of values, like ["us-west-1a", "us-west-1c"]. Elements in a list or tuple are identified by consecutive whole numbers, starting with zero.
- Implement List function for variable `ec2_instance_type`
```t
# Implement List Function in variables.tf
variable "ec2_instance_type" {
  description = "EC2 Instance Type"
  type = list(string)
  default = ["t3.micro", "t3.small", "t3.medium"]
}

# Reference Values from List in ec2-instance.tf
instance_type = var.ec2_instance_type[0] --> t3.micro
instance_type = var.ec2_instance_type[1] --> t3.small
instance_type = var.ec2_instance_type[2] --> t3.medium

# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan 
```

### Step-08-02: Implement Vairable Type as Map
- **map (or object):** a group of values identified by named labels, like {name = "Mabel", age = 52}.
- Implement Map function for variable `ec2_instance_tags`
```t
# Implement Map Function for tags
variable "ec2_instance_tags" {
  description = "EC2 Instance Tags"
  type = map(string)
  default = {
    "Name" = "ec2-web"
    "Tier" = "Web"
  }

# Reference Values from Map in ec2-instance.tf
tags = var.ec2_instance_tags  

# Implement Map Function for Instance Type
# Important Note: comment "ec2_instance_type" variable with list function
variable "ec2_instance_type_map" {
  description = "EC2 Instance Type using maps"
  type = map(string)
  default = {
    "small-apps" = "t3.micro"
    "medium-apps" = "t3.medium" 
    "big-apps" = "t3.large"
  }

# Reference Instance Type from Maps Variables
instance_type = var.ec2_instance_type_map["small-apps"]
instance_type = var.ec2_instance_type_map["medium-apps"]
instance_type = var.ec2_instance_type_map["big-apps"]

# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan 
```



## Step-09: Implement Custom Validation Rules in Variables
- **Reference Sub folder:** v9-Input-Variables-Validation-Rules
- Understand and implement custom validation rules in variables
- [Terraform Console](https://www.terraform.io/docs/cli/commands/console.html)
- The `terraform console` command provides an interactive console for evaluating expressions.
### Step-09-01: Learn Terraform Length Function
- [Terraform Length Function](https://www.terraform.io/docs/language/functions/length.html)
```t
# Go to Terraform Console
terraform console

# Test length function
Template: length()
length("hi")
length("hello")
length(["a", "b", "c"]) # List
length({"key" = "value"}) # Map
length({"key1" = "value1", "key2" = "value2" }) #Map
```

### Step-09-02: Learn Terraform SubString Function
- [Terraform Sub String Function](https://www.terraform.io/docs/language/functions/substr.html)
```t
# Go to Terraform Console
terraform console

# Test substr function
Template: substr(string, offset, length)
substr("stack simplify", 1, 4)
substr("stack simplify", 0, 6)
substr("stack simplify", 0, 1)
substr("stack simplify", 0, 0)
substr("stack simplify", 0, 10)
```

### Step-09-03: Implement Validation Rule for ec2_ami_id variable
```t
variable "ec2_ami_id" {
  description = "AMI ID"
  type = string  
  default = "ami-0be2609ba883822ec"
  validation {
    condition = length(var.ec2_ami_id) > 4 && substr(var.ec2_ami_id, 0, 4) == "ami-"
    error_message = "The ec2_ami_id value must be a valid AMI id, starting with \"ami-\"."
  }
}
```
- **Run Terraform commands**
```
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan
```

## Step-10: Protect Sensitive Input Variables
- **Reference Sub folder:** v10-Sensitive-Input-Variables
- [AWS RDS DB Instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [Vault Provider](https://learn.hashicorp.com/tutorials/terraform/secrets-vault?in=terraform/secrets)
- When using environment variables to set sensitive values, keep in mind that those values will be in your environment and command-line history
`Example: export TF_VAR_db_username=admin TF_VAR_db_password=adifferentpassword`
- When you use sensitive variables in your Terraform configuration, you can use them as you would any other variable. 
- Terraform will `redact` these values in command output and log files, and raise an error when it detects that they will be exposed in other ways.
- **Important Note-1:** Never check-in `secrets.tfvars` to git repositories
- **Important Note-2:** Terraform state file contains values for these sensitive variables `terraform.tfstate`. You must keep your state file secure to avoid exposing this data.
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan -var-file="secrets.tfvars"

# Create Resources
terraform apply -var-file="secrets.tfvars"

# Verify Terraform State files
grep password terraform.tfstate
grep username terraform.tfstate 

# Destroy Resources
terraform destroy var-file="secrets.tfvars"

# Clean-Up
rm -rf .terraform*
rm -rf terraform.tfstate*
```

### Variable Definition Precedence
- [Terraform Variable Definition Precedence](https://www.terraform.io/docs/language/values/variables.html#variable-definition-precedence)


## Step-11: Understand about `File` function
- **Reference Sub folder:** v11-File-Function
- Understand about [Terraform File Function](https://www.terraform.io/docs/language/functions/file.html)

```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan 

# Create Resources
terraform apply 

# Access Application
http://<Public-IP>

# Destroy Resources
terraform destroy -auto-approve
```


## References
- [Terraform Input Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Resource: AWS EC2 Instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Resource: AWS Security Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [Sensitive Variables - Additional Reference](https://learn.hashicorp.com/tutorials/terraform/sensitive-variables)



