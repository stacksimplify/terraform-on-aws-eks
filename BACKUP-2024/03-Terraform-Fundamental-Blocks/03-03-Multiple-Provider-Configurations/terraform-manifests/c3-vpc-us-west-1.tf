# Resource Block to Create VPC in us-west-1
resource "aws_vpc" "vpc-us-west-1" {
  cidr_block = "10.1.0.0/16"
  provider = aws.aws-west-1
  tags = {
    "Name" = "vpc-us-west-1"
  }
}


/*
Additional Note: 
provider = <PROVIDER NAME>.<ALIAS>  # This is a Meta-Argument from Resources Section nothing but a Special Argument
*/