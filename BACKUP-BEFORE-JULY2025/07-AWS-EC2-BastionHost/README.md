---
title: AWS EC2 Bastion Host in Public Subnet
description: Create AWS EC2 Bastion Host used to connect to EKS Node Group EC2 VMs
---

## Step-00: Introduction 
1. For VPC switch Availability Zones from Static to Dynamic using Datasource `aws_availability_zones`
2. Create EC2 Key pair that will be used for connecting to Bastion Host and EKS Node Group EC2 VM Instances
3. EC2 Bastion Host - [Terraform Input Variables](https://www.terraform.io/docs/language/values/variables.html)
4. EC2 Bastion Host - [AWS Security Group Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest)
5. EC2 Bastion Host - [AWS AMI Datasource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) (Dynamically lookup the latest Amazon2 Linux AMI)
6. EC2 Bastion Host - [AWS EC2 Instance Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest)
7. EC2 Bastion Host - [Terraform Resource AWS EC2 Elastic IP](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)
8. EC2 Bastion Host - [Terraform Provisioners](https://www.terraform.io/docs/language/resources/provisioners/syntax.html)
   - [File provisioner](https://www.terraform.io/docs/language/resources/provisioners/file.html)
   - [remote-exec provisioner](https://www.terraform.io/docs/language/resources/provisioners/local-exec.html)
   - [local-exec provisioner](https://www.terraform.io/docs/language/resources/provisioners/remote-exec.html)
9. EC2 Bastion Host - [Output Values](https://www.terraform.io/docs/language/values/outputs.html)
10. EC2 Bastion Host - ec2bastion.auto.tfvars
11. EKS Input Variables 
12. EKS [Local Values](https://www.terraform.io/docs/language/values/locals.html)
13. EKS Tags in VPC for Public and Private Subnets
14. Execute Terraform Commands and Test
15. Elastic IP - [depends_on Meta Argument](https://www.terraform.io/docs/language/meta-arguments/depends_on.html)

## Step-01: For VPC switch Availability Zones from Static to Dynamic
- [Datasource: aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones)
- **File Name:** `c3-02-vpc-module.tf` for changes 1 and 2
```t
# Change-1: Add Datasource named aws_availability_zones
# AWS Availability Zones Datasource  
data "aws_availability_zones" "available" {
}

# Change-2: Update the same in VPC Module
  azs             = data.aws_availability_zones.available.names

# Change-3: Comment vpc_availability_zones variable in File: c3-01-vpc-variables.tf
/*
variable "vpc_availability_zones" {
  description = "VPC Availability Zones"
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
*/

# Change-4: Comment hard-coded Availability Zones variable in File: vpc.auto.tfvars 
#vpc_availability_zones = ["us-east-1a", "us-east-1b"]  
```

## Step-02: Create EC2 Key pair and save it
- Go to Services -> EC2 -> Network & Security -> Key Pairs -> Create Key Pair
- **Name:** eks-terraform-key
- **Key Pair Type:** RSA (leave to defaults)
- **Private key file format:** .pem
- Click on **Create key pair**
- COPY the downloaded key pair to `terraform-manifests/private-key` folder
- Provide permissions as `chmod 400 keypair-name`
```t
# Provider Permissions to EC2 Key Pair
cd terraform-manifests/private-key
chmod 400 eks-terraform-key.pem
```
## Step-03: c4-01-ec2bastion-variables.tf
```t
# AWS EC2 Instance Terraform Variables

# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"  
}

# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  default = "eks-terraform-key"
}
```
## Step-04: c4-03-ec2bastion-securitygroups.tf
```t
# AWS EC2 Security Group Terraform Module
# Security Group for Public Bastion Host
module "public_bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.5.0"

  name = "${local.name}-public-bastion-sg"
  description = "Security Group with SSH port open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags = local.common_tags
}
```

## Step-05: c4-04-ami-datasource.tf
```t
# Get latest AMI ID for Amazon Linux2 OS
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-gp2" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}
```

## Step-06: c4-05-ec2bastion-instance.tf
```t
# AWS EC2 Instance Terraform Module
# Bastion Host - EC2 Instance that will be created in VPC Public Subnet
module "ec2_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.3.0"
  # insert the required variables here
  name                   = "${local.name}-BastionHost"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  #monitoring             = true
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.public_bastion_sg.security_group_id]
  tags = local.common_tags
}
```

## Step-07: c4-06-ec2bastion-elasticip.tf
```t
# Create Elastic IP for Bastion Host
# Resource - depends_on Meta-Argument
resource "aws_eip" "bastion_eip" {
  depends_on = [ module.ec2_public, module.vpc ]
  instance = module.ec2_public.id
  vpc      = true
  tags = local.common_tags
}
```
## Step-08: c4-07-ec2bastion-provisioners.tf
```t
# Create a Null Resource and Provisioners
resource "null_resource" "copy_ec2_keys" {
  depends_on = [module.ec2_public]
  # Connection Block for Provisioners to connect to EC2 Instance
  connection {
    type     = "ssh"
    host     = aws_eip.bastion_eip.public_ip    
    user     = "ec2-user"
    password = ""
    private_key = file("private-key/eks-terraform-key.pem")
  }  

## File Provisioner: Copies the terraform-key.pem file to /tmp/terraform-key.pem
  provisioner "file" {
    source      = "private-key/eks-terraform-key.pem"
    destination = "/tmp/eks-terraform-key.pem"
  }
## Remote Exec Provisioner: Using remote-exec provisioner fix the private key permissions on Bastion Host
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/eks-terraform-key.pem"
    ]
  }
## Local Exec Provisioner:  local-exec provisioner (Creation-Time Provisioner - Triggered during Create Resource)
  provisioner "local-exec" {
    command = "echo VPC created on `date` and VPC ID: ${module.vpc.vpc_id} >> creation-time-vpc-id.txt"
    working_dir = "local-exec-output-files/"
    #on_failure = continue
  }

}
```

## Step-09: ec2bastion.auto.tfvars
```t
instance_type = "t3.micro"
instance_keypair = "eks-terraform-key"
```

## Step-10: c4-02-ec2bastion-outputs.tf
```t
# AWS EC2 Instance Terraform Outputs
# Public EC2 Instances - Bastion Host

## ec2_bastion_public_instance_ids
output "ec2_bastion_public_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_public.id
}

## ec2_bastion_public_ip
output "ec2_bastion_eip" {
  description = "Elastic IP associated to the Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}

```

## Step-11: c5-01-eks-variables.tf
```t
# EKS Cluster Input Variables
variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources."
  type        = string
  default     = "eksdemo"
}
```



## Step-12: eks.auto.tfvars
```t
cluster_name = "eksdemo1"
```

## Step-13: c2-02-local-values.tf
```t
# Add additional local value
  eks_cluster_name = "${local.name}-${var.cluster_name}"  
```

## Step-14: c3-02-vpc-module.tf
- Update VPC Tags to Support EKS
```t
# Create VPC Terraform Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"
  #version = "~> 3.11"

  # VPC Basic Details
  name = local.eks_cluster_name
  cidr = var.vpc_cidr_block
  azs             = data.aws_availability_zones.available.names
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets  

  # Database Subnets
  database_subnets = var.vpc_database_subnets
  create_database_subnet_group = var.vpc_create_database_subnet_group
  create_database_subnet_route_table = var.vpc_create_database_subnet_route_table
  # create_database_internet_gateway_route = true
  # create_database_nat_gateway_route = true
  
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = var.vpc_enable_nat_gateway 
  single_nat_gateway = var.vpc_single_nat_gateway

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true

  
  tags = local.common_tags
  vpc_tags = local.common_tags

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "Public Subnets"
    "kubernetes.io/role/elb" = 1    
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"        
  }
  private_subnet_tags = {
    Type = "private-subnets"
    "kubernetes.io/role/internal-elb" = 1    
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"    
  }

  database_subnet_tags = {
    Type = "database-subnets"
  }
}
```

## Step-15: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-16: Verify the following
1. Verify VPC Tags
2. Verify Bastion EC2 Instance 
3. Verify Bastion EC2 Instance Security Group
4. Connect to Bastion EC2 Instnace
```t
# Connect to Bastion EC2 Instance
ssh -i private-key/eks-terraform-key.pem ec2-user@<Elastic-IP-Bastion-Host>
sudo su -

# Verify File and Remote Exec Provisioners moved the EKS PEM file
cd /tmp
ls -lrta
Observation: We should find the file named "eks-terraform-key.pem" moved from our local desktop to Bastion EC2 Instance "/tmp" folder
```

## Step-17: Clean-Up
```t
# Delete Resources
terraform destroy -auto-approve
terraform apply -destroy -auto-approve

# Delete Files
rm -rf .terraform* terraform.tfstate*
```