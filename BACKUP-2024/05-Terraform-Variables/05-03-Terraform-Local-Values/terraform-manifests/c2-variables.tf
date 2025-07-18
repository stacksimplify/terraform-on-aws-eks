# Input Variables
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"
}

# App Name S3 Bucket used for
variable "app_name" {
  description = "Application Name"
  type = string
}

# Environment Name
variable "environment_name" {
  description = "Environment Name"
  type = string
}



