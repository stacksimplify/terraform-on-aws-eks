resource "aws_instance" "myec2vm" {
  ami           = "ami-0c30b7300f5fb34cd"
  instance_type = "t3.micro"

  user_data = file("${path.module}/app1-install.sh")

  vpc_security_group_ids = [
    "sg-0a9ce4803ddf566ea"
  ]

  associate_public_ip_address = true

  tags = {
    Name = "EC2 Demo"
  }
}
