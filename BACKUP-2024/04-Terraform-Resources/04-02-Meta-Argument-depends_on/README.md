# Terraform Resource Meta-Argument depends_on

## Step-01: Introduction
- Create 9 aws resources in a step by step manner
- Create Terraform Block
- Create Provider Block
- Create 9 Resource Blocks
  - Create VPC
  - Create Subnet
  - Create Internet Gateway
  - Create Route Table
  - Create Route in Route Table for Internet Access
  - Associate Route Table with Subnet
  - Create Security Group in the VPC with port 80, 22 as inbound open
  - Create EC2 Instance in respective new vpc, new subnet created above with a static key pair, associate Security group created earlier
  - Create Elastic IP Address and Associate to EC2 Instance
  - Use `depends_on` Resource Meta-Argument attribute when creating Elastic IP  

## Step-02: Pre-requisite - Create a EC2 Key Pair
- Create EC2 Key pair `terraform-key` and download pem file and put ready for SSH login

## Step-03: c1-versions.tf - Create Terraform & Provider Blocks 
- Create Terraform Block
- Create Provider Block
```
# Terraform Block
terraform {
  required_version = ">= 1.4" 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Provider Block
provider "aws" {
  region = "us-east-1"
  profile = "default"
}
```
## Step-04: c2-vpc.tf - Create VPC Resources 
### Step-04-01: Create VPC using AWS Management Console
- Create VPC Manually and understand all the resources we are going to create. Delete that VPC and start writing the VPC template using terraform
### Step-04-02: Create VPC using Terraform
- Create VPC Resources listed below  
  - Create VPC
  - Create Subnet
  - Create Internet Gateway
  - Create Route Table
  - Create Route in Route Table for Internet Access
  - Associate Route Table with Subnet
  - Create Security Group in the VPC with port 80, 22 as inbound open
```
# Resource Block
# Resource-1: Create VPC
resource "aws_vpc" "vpc-dev" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "name" = "vpc-dev"
  }
}

# Resource-2: Create Subnets
resource "aws_subnet" "vpc-dev-public-subnet-1" {
  vpc_id = aws_vpc.vpc-dev.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}


# Resource-3: Internet Gateway
resource "aws_internet_gateway" "vpc-dev-igw" {
  vpc_id = aws_vpc.vpc-dev.id
}

# Resource-4: Create Route Table
resource "aws_route_table" "vpc-dev-public-route-table" {
  vpc_id = aws_vpc.vpc-dev.id
}

# Resource-5: Create Route in Route Table for Internet Access
resource "aws_route" "vpc-dev-public-route" {
  route_table_id = aws_route_table.vpc-dev-public-route-table.id 
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpc-dev-igw.id 
}


# Resource-6: Associate the Route Table with the Subnet
resource "aws_route_table_association" "vpc-dev-public-route-table-associate" {
  route_table_id = aws_route_table.vpc-dev-public-route-table.id 
  subnet_id = aws_subnet.vpc-dev-public-subnet-1.id
}

# Resource-7: Create Security Group
resource "aws_security_group" "dev-vpc-sg" {
  name = "dev-vpc-default-sg"
  vpc_id = aws_vpc.vpc-dev.id
  description = "Dev VPC Default Security Group"

  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
```

## Step-05: c3-ec2-instance.tf - Create EC2 Instance Resource
- Review `apache-install.sh`
```sh
#! /bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo service httpd start  
sudo systemctl enable httpd
echo "<h1>Welcome to StackSimplify ! AWS Infra created using Terraform in us-east-1 Region</h1>" > /var/www/html/index.html
```
- Create EC2 Instance Resource
```
# Resource-8: Create EC2 Instance
resource "aws_instance" "my-ec2-vm" {
  ami = "ami-0be2609ba883822ec" # Amazon Linux
  instance_type = "t2.micro"
  subnet_id = aws_subnet.vpc-dev-public-subnet-1.id
  key_name = "terraform-key"
	#user_data = file("apache-install.sh")
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<h1>Welcome to StackSimplify ! AWS Infra created using Terraform in us-east-1 Region</h1>" > /var/www/html/index.html
    EOF  
  vpc_security_group_ids = [ aws_security_group.dev-vpc-sg.id ]
}
```

## Step-06: c4-elastic-ip.tf - Create Elastic IP Resource
- Create Elastic IP Resource
- Add a Resource Meta-Argument `depends_on` ensuring Elastic IP gets created only after AWS Internet Gateway in a VPC is present or created
```
# Resource-9: Create Elastic IP
resource "aws_eip" "my-eip" {
  instance = aws_instance.my-ec2-vm.id
  vpc = true
  depends_on = [ aws_internet_gateway.vpc-dev-igw ]
}
```

## Step-07: Execute Terraform commands to Create Resources using Terraform
```
# Initialize Terraform
terraform init

# Terraform Validate
terraform validate

# Terraform Plan to Verify what it is going to create / update / destroy
terraform plan

# Terraform Apply to Create EC2 Instance
terraform apply 
```

## Step-08: Verify the Resources
- Verify VPC
- Verify EC2 Instance
- Verify Elastic IP
- Review the `terraform.tfstate` file
- Access Apache Webserver Static page using Elastic IP
```
# Access Application
http://<AWS-ELASTIC-IP>
```

## Step-09: Destroy Terraform Resources
```
# Destroy Terraform Resources
terraform destroy

# Remove Terraform Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## References 
- [Elastic IP creation depends on VPC Internet Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)
- [Resource: aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [Resource: aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)
- [Resource: aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)
- [Resource: aws_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)
- [Resource: aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)
- [Resource: aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)
- [Resource: aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [Resource: aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Resource: aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)