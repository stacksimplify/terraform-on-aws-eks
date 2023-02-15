# Resource: EC2 Instance
resource "aws_instance" "myEC2server" {
  ami = "ami-0dfcb1ef8550277af"
  instance_type = "t3.micro"
  user_data = file("${path.module}/data_user.sh")
  tags = {
    "Name" = "EC2-Server"
  }
}