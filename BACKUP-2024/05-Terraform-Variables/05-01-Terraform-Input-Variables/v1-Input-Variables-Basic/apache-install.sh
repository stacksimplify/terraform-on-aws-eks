#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl start httpd
echo "<html><body><div>Welcome to StackSimplify ! AWS Infra created using Terraform</div></body></html>" > /var/www/html/index.html
