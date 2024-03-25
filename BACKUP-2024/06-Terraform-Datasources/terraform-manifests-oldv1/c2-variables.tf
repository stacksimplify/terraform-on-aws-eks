# Input Variables
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"
}

/* 
# Commented as we are going to get AMI ID from Datasource aws_ami
variable "ec2_ami_id" {
  description = "AMI ID"
  type = string  
  default = "ami-0915bcb5fa77e4892"
}
*/

variable "ec2_instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"
}

