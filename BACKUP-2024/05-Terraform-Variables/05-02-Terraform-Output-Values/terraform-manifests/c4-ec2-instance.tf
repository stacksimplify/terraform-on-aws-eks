# Create EC2 Instance
resource "aws_instance" "my-ec2-vm" {
  ami           = var.ec2_ami_id 
  instance_type = var.ec2_instance_type
  key_name      = "terraform-key"
	user_data = file("apache-install.sh")  
  /*
    user_data     = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<html><body><div>Welcome to StackSimplify ! AWS Infra created using Terraform</div></body></html>" > /var/www/html/index.html
    EOF
  */
  vpc_security_group_ids = [aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id]
  tags = {
    "Name" = "web"
  }
}


