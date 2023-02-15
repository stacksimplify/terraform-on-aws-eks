#! /bin/bash
# Instance Identity Metadata Reference - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
#!/bin/bash
# Update system and install basic things
sudo yum -y update
sudo yum install -y curl unzip wget gcc-c++ make git
sudo amazon-linux-extras install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo pip3 install jinja2
# Install java 8 client for jenkins
sudo yum install -y java-1.8.0-openjdk
# Install the AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
export PATH=$PATH:/usr/local/aws-cli/v2/current/bin
# Install docker
sudo amazon-linux-extras install -y docker
systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
# Install terraform 
wget https://releases.hashicorp.com/terraform/1.3.7/terraform_1.3.7_linux_amd64.zip
unzip terraform_1.3.7_linux_amd64.zip
chmod +x terraform 
sudo mv terraform /usr/local/bin/
# Install Kubectl the system
curl -LO "https://dl.k8s.io/release/stable.txt"
KUBE_VERSION=$(cat stable.txt)
curl -LO "https://dl.k8s.io/${KUBE_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
# Install Node.js 14
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs
# Download and Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.0/install.sh | bash
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bash_profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bash_profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bash_profile
source ~/.bash_profile
sudo nvm install 14
# Verify the installations
sudo cp -r /usr/local/bin/kubectl /home/ec2-user/ 
node --version
kubectl version --client
terraform -v
aws --version
/home/ec2-user/kubectl version --client


