# Terraform Dynamic Expressions

## Step-01: Introduction
- Learn [Dynamic Expressions](https://www.terraform.io/docs/language/expressions/conditionals.html) in Terraform
- **Conditional Expression:** A conditional expression uses the value of a bool expression to select one of two values.
```t
# Example-1
condition ? true_val : false_val

# Example-2
var.a != "" ? var.a : "default-a"
```
- **Splat Expression:** A `splat expression` provides a more concise way to express a common operation that could otherwise be performed with a `for` expression.
- The special [*] symbol iterates over all of the elements of the list given to its left and accesses from each one the attribute name given on its right. 
```t
# With for expression
[for o in var.list : o.id]

# With Splat Expression [*]
var.list[*].id
```
- A splat expression can also be used to access attributes and indexes from lists of complex types by extending the sequence of operations to the right of the symbol:
```t
var.list[*].interfaces[0].name
aws_instance.example[*].id
```


## Step-02: Review Terraform Manifests
### c1-versions.tf
- Added new random provider in `required_providers` block
### c2-vairables.tf
  - Added new variables
  - availability_zones
  - name
  - team
  - high_availability
### c3-security-groups.tf
  - Added common tags
### c4-ec2-instance.tf
- Added Random ID resource block
- Added new locals block
- **Important Note:** Inside locals block we can add conditional expressions as below. 
```t
# Create Locals
locals {
  #name = var.name
  name  = (var.name != "" ? var.name : random_id.id.hex)
  owner = var.team
  common_tags = {
    Owner = local.owner
    DefaultUser = local.name 
  }
}
```
- Added Availability zone argument with count.index
- We will discuss about following conditional expressions here
```t
# In Locals Block: Conditional Expression
name  = (var.name != "" ? var.name : random_id.id.hex)

# In EC2 Resource Block: Conditional Expression
count = (var.high_availability == true ? 2 : 1)

# In EC2 Resource Block: count.index
availability_zone = var.availability_zones[count.index]
```
### c5-outputs.tf
- Added Splat expression [*] for all outputs
- Added Common Tags and ELB DNS Name as new outputs

### c6-ami-datasource.tf
- No changes

### c7-elb.tf
- Added this new resource
- We will be creating ELB only if "high_availability" variable value is true else it will not be created
```t
# Create ELB if high_availability=true
# In ELB Block: Conditional Expression
count = (var.high_availability == true ? 1 : 0)
```  

## Step-03: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan: When Variable values, high_availability = false and name = "ec2-user"
terraform plan
Observation: 
1) Plan will generate for only 1 EC2 instance and 2 Security Groups.
2) ELB Resource will not be created with these variable options


# Terraform Plan: When Variable values, high_availability = true and name = ""
terraform plan
1) Plan will generate for only 2 EC2 instance, 2 Security Groups and 1 ELB
2) ELB Resource will be created with these variable options
3) name value will be a random value known after terraform apply completed

# Terraform Apply
terraform apply -auto-approve

# Verify
1) Verify Outputs
2) Verify EC2 Instances & Security Groups & Common Tags
3) Verify ELB & Common Tags for ELB
4) Access App using ELB DNS Name
```

## Step-04: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Clean-Up
rm -rf .terraform*
rm -rf terraform.tfstate*

# Uncomment and Comment right values in c2-variables.tf (Roll back to put ready for student demo)
high_availability = false 
name = "ec2-user"
```

