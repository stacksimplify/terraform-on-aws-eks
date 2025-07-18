# Terraform Provider Block

## Step-01: Introduction
- What are Terraform Providers?
- What Providers Do?
- Where do providers reside (Terraform Registry)?
- How to use Providers?
- What are Provider Badges?


## Step-02: Terraform Providers
- What are Terraform Providers?
- What Providers Do?
- Where do providers reside (Terraform Registry)?


## Step-03: Provider Requirements
- Define required providers in Terraform Block
- Understand about three things about defining `required_providers` in terraform block
  - local names
  - source
  - version
```t
# Terraform Block
terraform {
  required_version = "~> 0.14.4"
  required_providers {
    aws = { 
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
```


## Step-04: Provider Block  
- Create a Provider Block for AWS
```t
# Provider Block
provider "aws" {
  region = "us-east-1"
  profile = "default"  # defining it is optional for default profile
}
```
- Discuss about [Authentication Types](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) 
- Static Credentials - NOT A RECOMMENDED Option
- Environment variables
- Shared credentials/configuration file ( We are going to use this)
  - Verify your `cat $HOME/.aws/credentials`
  - If not, use `aws configure` to configure the aws credentials

```t
# Initialize Terraform
terraform init

# Validate Terraform Configuration files
terraform validate

# Execute Terraform Plan
terraform plan
```  

## Step-05: Add a Resource Block to create a AWS VPC
- [AWS VPC Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
```t
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "myvpc"
  }
}
```

## Step-06: Execute Terraform commands to create AWS VPC
```t
# Initialize Terraform
terraform init

# Validate Terraform Configuration files
terraform validate

# Execute Terraform Plan
terraform plan

# Create Resources using Terraform Apply
terraform apply -auto-approve
```  

## Step-07: Clean-Up 
```t
# Destroy Terraform Resources
terraform destroy -auto-approve

# Delete Terraform Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```


## References
- [Terraform Providers](https://www.terraform.io/docs/configuration/providers.html)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)