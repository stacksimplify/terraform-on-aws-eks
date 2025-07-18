# Create S3 Bucket - with Input Variables 
/*
resource "aws_s3_bucket" "mys3bucket" {
  bucket = "${var.app_name}-${var.environment_name}-bucket"
  acl = "private"
  tags = {
    Name = "${var.app_name}-${var.environment_name}-bucket"
    Environment = var.environment_name
  }
}
*/

# Define Local Values
locals {
  bucket-name = "${var.app_name}-${var.environment_name}-bucket" # Complex expression
}

# Create S3 Bucket - with Input Variables & Local Values
resource "aws_s3_bucket" "mys3bucket" {
  bucket = local.bucket-name
  acl = "private"
  tags = {
    Name = local.bucket-name
    Environment = var.environment_name
  }
}