# Terraform Resource Meta-Argument count

## Step-01: Introduction
- Understand Resource Meta-Argument `count`
- Also implement count and count index practically 

## Step-02: Create 5 EC2 Instances using Terraform
- In general, 1 EC2 Instance Resource in Terraform equals to 1 EC2 Instance in Real AWS Cloud
- 5 EC2 Instance Resources = 5 EC2 Instances in AWS Cloud
- With `Meta-Argument count` this is going to become super simple. 
- Lets see how. 
```t
# Create EC2 Instance
resource "aws_instance" "web" {
  ami = "ami-047a51fa27710816e" # Amazon Linux
  instance_type = "t2.micro"
  count = 5
  tags = {
    "Name" = "web"
  }
}
```
- **Execute Terraform Commands**
```t
# Initialize Terraform
terraform init

# Terraform Validate
terraform validate

# Terraform Plan to Verify what it is going to create / update / destroy
terraform plan

# Terraform Apply to Create EC2 Instance
terraform apply 
```
- Verify EC2 Instances and its Name


## Step-03: Understand about count index
- If we currently see all our EC2 Instances has the same name `web`
- Lets name them by using count index `web-0, web-1, web-2, web-3, web-4`
```t
# Create EC2 Instance
resource "aws_instance" "web" {
  ami = "ami-047a51fa27710816e" # Amazon Linux
  instance_type = "t2.micro"
  count = 5
  tags = {
    #"Name" = "web"
    "Name" = "web-${count.index}"
  }
}
```
- **Execute Terraform Commands**
```t
# Terraform Validate
terraform validate

# Terraform Plan to Verify what it is going to create / update / destroy
terraform plan

# Terraform Apply to Create EC2 Instance
terraform apply 
```
- Verify EC2 Instances


## Step-04: Destroy Terraform Resources
```t
# Destroy Terraform Resources
terraform destroy

# Remove Terraform Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## References
- [Resources: Count Meta-Argument](https://www.terraform.io/docs/language/meta-arguments/count.html)