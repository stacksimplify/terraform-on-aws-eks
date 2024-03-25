# Define Ports as a list in locals block
locals {
  ports = [80, 443, 8080, 8081, 7080, 7081]
}

# Create Security Group using Terraform Dynamic Block
resource "aws_security_group" "sg-dynamic" {
  name = "dynamic-block-demo"
  description = "dynamic-block-demo"

  dynamic "ingress" {
    for_each = local.ports 
    content {
      description = "description ${ingress.key}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

