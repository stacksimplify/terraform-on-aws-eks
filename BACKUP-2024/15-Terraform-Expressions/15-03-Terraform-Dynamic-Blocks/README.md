# Terraform Dynamic Blocks

## Step-01: Introduction
- Some resource types include repeatable nested blocks in their arguments, which do not accept expressions
- You can dynamically construct repeatable nested blocks like setting using a special dynamic block type, which is supported inside resource, data, provider, and provisioner blocks

## Step-02: Create / Review Terraform manifests
### c1-versions.tf
- Standard file without any changes
- `region` in provider block is hard-coded to `us-east-1`
### c2-security-groups-regular.tf
```t
resource "aws_security_group" "sg-regular" {
  name        = "demo-regular"
  description = "demo-regular"

  ingress {
    description = "description 0"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "description 1"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "description 2"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "description 3"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "description 4"
    from_port   = 7080
    to_port     = 7080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }      
  ingress {
    description = "description 5"
    from_port   = 7081
    to_port     = 7081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }      
}
```

### c3-dynamic-blocks-for-security-groups.tf
- ingress.key = 0 and ingress.value = 80
- ingress.key = 1 and ingress.value = 443
- ingress.key = 2 and ingress.value = 8080  ....
```t
# Define Ports as a list in locals block
locals {
  ports = [80, 443, 8080, 8081, 7080, 7081]
}

# Create Security Group using Terraform Dynamic Block
resource "aws_security_group" "sg-dynamic" {
  name        = "dynamic-block-demo"
  description = "dynamic-block-demo"

  dynamic "ingress" {
    for_each = local.ports
    content {
      description = "description ${ingress.key}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

## Step-03: Execute Terraform Commands
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

## Step-04: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```