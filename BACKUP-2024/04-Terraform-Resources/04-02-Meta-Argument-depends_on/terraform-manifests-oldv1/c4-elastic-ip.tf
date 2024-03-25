# Resource-9: Create Elastic IP
resource "aws_eip" "my-eip" {
  instance = aws_instance.my-ec2-vm.id
  vpc      = true
  # Meta-Argument
  depends_on = [aws_internet_gateway.vpc-dev-igw]
}
