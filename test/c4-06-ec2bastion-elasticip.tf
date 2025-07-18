# Create Elastic IP for Bastion Host
# Resource - depends_on Meta-Argument
resource "aws_eip" "bastion_eip" {
  depends_on = [aws_instance.ec2_public, aws_vpc.vpc]
  instance   = aws_instance.ec2_public.id
  #vpc      = true
  domain = "vpc"
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-eip"
    }
  )
}

