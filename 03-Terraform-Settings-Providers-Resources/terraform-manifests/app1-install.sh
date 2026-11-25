#!/bin/bash

# Update packages
apt-get update -y

# Install Apache
apt-get install -y apache2

# Enable and start Apache
systemctl enable apache2
systemctl start apache2

# Create default webpage
echo '<h1>Welcome to StackSimplify - APP-1</h1>' > /var/www/html/index.html

# Create app1 directory
mkdir -p /var/www/html/app1

# Create application webpage
cat <<EOF > /var/www/html/app1/index.html
<!DOCTYPE html>
<html>
<body style="background-color:rgb(250, 210, 210);">
<h1>Welcome to Stack Simplify - APP-1</h1>
<p>Terraform Demo</p>
<p>Application Version: V1</p>
</body>
</html>
EOF

# Fetch EC2 metadata using IMDSv2
TOKEN=$(curl -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

curl -f \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/dynamic/instance-identity/document \
  -o /var/www/html/app1/metadata.html