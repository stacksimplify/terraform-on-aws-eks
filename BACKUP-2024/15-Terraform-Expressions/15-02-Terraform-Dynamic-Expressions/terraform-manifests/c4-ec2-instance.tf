# Define Random ID Resource
resource "random_id" "id" {
  byte_length = 8
}

# Create Locals
locals {
  # name = var.name
  name  = (var.name != "" ? var.name : random_id.id.hex)
  owner = var.team
  common_tags = {
    Owner = local.owner
    nametag = local.name 
  }
}


# Create EC2 Instance - Amazon Linux
resource "aws_instance" "my-ec2-vm" {
  ami           = data.aws_ami.amzlinux.id
  instance_type = var.instance_type
  key_name      = "terraform-key"
	user_data = file("apache-install.sh")  
  vpc_security_group_ids = [aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id]
  # Dynamic Expressions
  count = (var.high_availability == true ? 2 : 1)
  tags = local.common_tags
  availability_zone = var.availability_zones[count.index]
}


