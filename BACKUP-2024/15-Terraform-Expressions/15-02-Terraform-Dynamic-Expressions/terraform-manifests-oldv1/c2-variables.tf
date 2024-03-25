# Input Variables
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"
}

variable "availability_zones" {
  description = "List of Availability Zones resources will be created"
  type = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "high_availability" {
  type        = bool
  description = "If this is a multiple instance deployment, choose `true` to deploy 2 instances"
  default     = false
  #default     = true
}


variable "name" {
  description = "The username assigned to the infrastructure"
  type = string 
  default     = "ec2-user"
  #default     = ""
}

variable "team" {
  description = "The team responsible for the infrastructure"
  type = string
  default     = "stacksimplify"
}

