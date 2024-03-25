# Providers - Dependency Lock File

## Step-01: Introduction
- Understand the importance of Dependency Lock File which is introduced in Terraform v0.14

## Step-02: Review the Terraform Manifests
- c1-versions.tf
  - Discuss about Terraform, AWS and Random Pet Provider Versions
- c2-s3bucket.tf
  - Discuss about Random Pet Resource
  - Discuss about S3 Bucket Resource
- .terraform.lock.hcl
  - Discuss about Provider Version, Version Constraints and Hashes

## Step-03: Initialize and apply the configuration
```t
# Initialize Terraform
terraform init

# Validate Terraform Configuration files
terraform validate

# Execute Terraform Plan
terraform plan

# Create Resources using Terraform Apply
terraform apply
```
- Review **.terraform.lock.hcl**
  - Discuss about versions
  - Compare `.terraform.lock.hcl-ORIGINAL` & `.terraform.lock.hcl`
  - Backup `.terraform.lock.hcl` as `.terraform.lock.hcl-FIRST-INIT` 
```
# Backup
cp .terraform.lock.hcl .terraform.lock.hcl-FIRST-INIT
```

## Step-04: Upgrade the AWS provider version
- For AWS Provider, with version constraint `version = ">= 2.0.0"`, it is going to upgrade to latest `3.x.x` version with command `terraform init -upgrade` 
```t
# Upgrade Provider Version
terraform init -upgrade
```
- Review **.terraform.lock.hcl**
  - Discuss about AWS Versions
  - Compare `.terraform.lock.hcl-FIRST-INIT` & `.terraform.lock.hcl`

## Step-05: Apply Terraform configuration with latest AWS Provider
- Should fail due to S3 related latest changes came in AWS v3.x provider when compared to AWS v2.x provider
```
# Terraform Apply
terraform apply
```

## Step-06: Comment region in S3 Resource and try Terraform Apply
- It should work. 
- When we do a major version upgrade to providers, it might break few features. 
- So with `.terraform.lock.hcl`, we can avoid this type of issues.
```
# Comment Region Attribute
# Resource Block: Create AWS S3 Bucket
resource "aws_s3_bucket" "sample" {
  bucket = random_pet.petname.id
  acl    = "public-read"

  #region = "us-west-2"
}

# Terraform Apply
terraform apply
```

## Step-07: Clean-Up
```
# Destroy Resources
terraform destroy

# Delete Terraform Files
rm -rf .terraform    # We are not removing files named ".terraform.lock.hcl, .terraform.lock.hcl-ORIGINAL" which are needed for this demo for you.
rm -rf terraform.tfstate*
```

## References
- [Random Pet Provider](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet)
- [Dependency Lock File](https://www.terraform.io/docs/configuration/dependency-lock.html)
- [Terraform New Features in v0.14](https://learn.hashicorp.com/tutorials/terraform/provider-versioning?in=terraform/0-14)
- [AWS S3 Bucket Region - Read Only in AWS Provider V3.x](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-3-upgrade#region-attribute-is-now-read-only)