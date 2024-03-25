# Create EC2 Instnace Resource
resource "aws_instance" "myec2vm" {
  
  /* 
  ami = "ami-038f1ca1bd58a5790"
  #instance_type = "t2.micro"
  instance_type = "t2.small" # Enabling it as part of Step-06
  availability_zone = "us-east-1e"
  key_name = "terraform-key"
  tags = {
    "Name" = "State-Import-Demo"
  }
  */
}
