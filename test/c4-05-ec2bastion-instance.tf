# AWS EC2 Instance Terraform Module
# Bastion Host - EC2 Instance that will be created in VPC Public Subnet
resource "aws_instance" "ec2_public" {
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  subnet_id              = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.public_bastion_sg.id]
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-BastionHost"
    }
  )
}

# AWS EC2 Instance Terraform Module
# Bastion Host - EC2 Instance that will be created in VPC Public Subnet
resource "aws_instance" "ec2_private" {
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  subnet_id              = aws_subnet.private_subnet[0].id
  vpc_security_group_ids = [aws_security_group.public_bastion_sg.id]
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-PrivateHost"
    }
  )
}