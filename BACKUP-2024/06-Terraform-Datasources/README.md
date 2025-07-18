# Terraform Datasources

## Step-01: Introduction
- Understand about Datasources in Terraform
- Implement a sample usecase with Datasources.
- Get the latest Amazon Linux 2 AMI ID using datasources and reference that value when creating EC2 Instance resource `ami = data.aws_ami.amzlinux.id`

## Step-02: Create a Datasource to fetch latest AMI ID
- Create or review manifest `c6-ami-datasource.tf`
- Go to AWS Mgmt Console -> Services -> EC2 -> Images -> AMI 
- Search for "Public Images" -> Provide AMI ID
  - We can get AMI Name format
  - We can get Owner Name
  - Visibility
  - Platform
  - Root Device Type
  - and many more info here. 
- Accordingly using this information build your filters in datasource

## Step-03: Reference the datasource in ec2-instance.tf
```t
  ami           = data.aws_ami.amzlinux.id 
```

## Step-04: Test using Terraform commands
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

# Access Application
http://<Public-DNS>

# Destroy Resources
terraform destroy -auto-approve
```


## References
- [AWS EC2 AMI Datasource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)
