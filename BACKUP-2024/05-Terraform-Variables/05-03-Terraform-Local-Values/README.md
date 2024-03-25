# Terraform Local Values

## Step-01: Introduction
- Understand DRY Principle
- What is local value in terraform?
- When To Use Local Values?
- What is the problem locals are solving ?

```
What is DRY Principle ?
Don't repeat yourself

What is local value in terraform?
The local block defines one or more local variables within a module. 
A local value assigns a name to an terraform expression, allowing it to be used multiple times within a module without repeating it.

When To Use Local Values?
Local values can be helpful to avoid repeating the same values or expressions multiple times in a configuration
If overused they can also make a configuration hard to read by future maintainers by hiding the actual values used.
Use local values only in moderation, in situations where a single value or result is used in many places and that value is likely to be changed in future. The ability to easily change the value in a central place is the key advantage of local values.

What is the problem locals are solving ?
Currently terraform doesn’t allow variable substitution within variables. The terraform way of doing this is by using local values or locals where you can somehow keep your code DRY.

Another use case (at least for me) for locals is to shorten references on upstream terraform projects as seen below. This will make your terraform templates/modules more readable.
```

## Step-02: Create / Review Terraform configuration files
- c1-versions.tf
- c2-variables.tf
- c3-s3-bucket.tf


## Step-03: Test the Terraform configuration using commands
```t
# Initialize Terraform
terraform init

# Validate Terraform configuration files
terraform validate

# Format Terraform configuration files
terraform fmt

# Review the terraform plan
terraform plan 

# Create Resources (Optional)
terraform apply -auto-approve
```

## References
- [Terraform Local values](https://www.terraform.io/docs/language/values/locals.html)