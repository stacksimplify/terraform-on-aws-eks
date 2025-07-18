# Terraform State Import

## Step-01: Introduction
### Some notes about Terraform Import Command
- Terraform is able to import existing infrastructure. 
- This allows you take resources you've created by some other means and bring it under Terraform management.
- This is a great way to slowly transition infrastructure to Terraform, or to be able to be confident that you can use Terraform in the future if it potentially doesn't support every feature you need today.
- [Full Reference](https://www.terraform.io/docs/cli/import/index.html)
### Two demos
- **Demo-1:** Create EC2 Instance manually and import state to manage it from Terraform
- **Demo-2:** Create S3 bucket manually and import state to mange it from Terraform


## Step-02: Create EC2 Instance manually using AWS mgmt Console
- Go to  Services -> Ec2 -> Instances -> Launch Instance
- **Step 1:** ChooseAMI: Amazon Linux 2 AMI (HVM), SSD Volume Type
- **Step 2:** Choose an Instance Type: t2.micro (leave to defaults)
- **Step 3:** Configure Instance Details: (Leave to defaults )
- **Step 4:** Add Storage (Leave to Defaults)
- **Step 5:** Add Tags
  - Key: Name
  - Value: State-Import-Demo
- **Step 6:** Configure Security Group: Select default VPC security group
- **Step 7:** Review Instance Launch
- Select an existing key pair: terraform-key
- Click on **Launch Instance**


## Step-03: Create Basic Terraform Configuration
- **Reference Folder:** v1-ec2-instance
- c1-versions.tf
- c2-ec2-instance.tf
- Create EC2 Instance Resource - Basic Version to get Terraform `Resource Type` and `Resource Local Name` we are going to use in Terraform
```t
# Create EC2 Instance Resource - Basic Version to get Terraform Resource Type and Resource Local Name we are going to use in Terraform
resource "aws_instance" "myec2vm" {
}
```

## Step-04: Run Terraform Import to import AWS EC2 Instance Resource to Terraform
- [Terraform AWS EC2 Instance Argument Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#argument-reference)
```t
# Terraform Initialize
terraform init

# Terraform Import Command for EC2 Instance
terraform import aws_instance.myec2vm <EC2-Instance-ID>
terraform import aws_instance.myec2vm i-0477f144280c37a7a
Observation:
1) terraform.tfstate file will be created locally in Terraform working directory
2) Review information about imported instance configuration in terraform.tfstate
```

## Step-05: Start Building local c2-ec2-instance.tf
- By referring `terraform.tfstate` file and parallely running `terraform plan` command make changes to your terraform configuration `c2-ec2-instance.tf` till you get the message `No changes. Infrastructure is up-to-date` for `terraform plan` output
```t
# Create EC2 Instance Resource 
resource "aws_instance" "myec2vm" {
  ami = "ami-038f1ca1bd58a5790"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "terraform-key"
  tags = {
    "Name" = "State-Import-Demo"
  }
}
```
## Step-06: Modify EC2 Instance from Terraform
- You have created this EC2 instance manually, now you made it as terraform managed 
- Modify Instance type to `t2.small` and test
```t
# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
Observation:
1) EC2 Instance Type on AWS Cloud should be changed from t2.micro to t2.small
```

## Step-06: Destroy EC2 Instance from Terraform 
- You have created this EC2 instance manually, now you made it as terraform managed
- Destroy that using terraform
```t
# Destroy Resource
terraform destroy  -auto-approve

# Clean-Up files
rm -rf .terraform*
rm -rf terraform.tfstate*

# Comment Resource Arguments for S3 bucket
Comment Arguments in c2-ec2-instance.tf so that when a student is using the demo, he can uncomment or write it as per their Ec2 Instance settings.
```
## NOT HAPPY - Lets do one more example with AWS S3 Bucket and learn little more about terraform state import


## Step-07: Create AWS S3 bucket manually using AWS mgmt Console
- Go to  Services -> S3 -> **Create Bucket**
- **Bucket Name:** state-import-bucket


## Step-08: Create Basic Terraform Configuration
- **Reference Folder:** v2-s3bucket
- c1-versions.tf
- c2-s3bucket.tf
- Create S3 Bucket Resource - Basic Version to get Terraform `Resource Type` and `Resource Local Name` we are going to use in Terraform
```t
# Create S3 Bucket
resource "aws_s3_bucket" "mybucket" {

}
```
## Step-09:Run Terraform Import Command to import AWS S3 bucket resource to Terraform
- [Terraform S3 Bucket Argument Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#argument-reference)
```t
# Terraform Initialize
terraform init

# Terraform Import Command for AWS S3 bucket
terraform import aws_s3_bucket.mybucket <BUCKET_NAME>
terraform import aws_s3_bucket.mybucket state-import-bucket
Observation:
1) terraform.tfstate file will be created locally in Terraform working directory
2) Review information about imported instance configuration in terraform.tfstate
```

## Step-10: Start Building local c2-s3bucket.tf
- By referring `terraform.tfstate` file and parallely running `terraform plan` command make changes to your terraform configuration `c2-s3bucket.tf` till you get the message `No changes. Infrastructure is up-to-date` for `terraform plan` output
- For S3 buckets, there will be some default parameters from terraform will be set for two arguments
  - acl =  private
  - force_destroy = false
- Those even though you manually add it, you also need to do `terraform apply` once to make terraform happy.
```t
# Create S3 Bucket
resource "aws_s3_bucket" "mybucket" {
  bucket = "state-import-bucket"
  acl = "private" 
  force_destroy = false # default is false make this to true if any contents in bucket, so in next step you can destroy using terraform
}

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```


## Step-11: Destroy S3 Bucket from Terraform 
- You have created this S3 Bucket manually, now you made it as terraform managed
- Destroy that using terraform
```t
# Destroy Resource
terraform destroy  -auto-approve

# Clean-Up files
rm -rf .terraform*
rm -rf terraform.tfstate*

# Comment Resource Arguments for S3 bucket
Comment Arguments in c2-s3bucket.tf so that when a student is using the demo, he can uncomment or write it as per their bucket names and settings.
```