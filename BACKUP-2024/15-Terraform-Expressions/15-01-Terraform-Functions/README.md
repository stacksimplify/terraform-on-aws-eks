# Terraform Functions

## Step-01: Introduction
- We are going to learn about different Terraform Functions using Terraform console command
- In detail, we are going to learn about `templatefile` and `concat` functions with an AWS example

## Step-02: Numeric Functions
```t
# Terraform Console
terraform console

# Min Function: Takes one or more numbers and returns the smallest number from the set.
min(12, 13, 14)

# Max Function: Takes one or more numbers and returns the greatest number from the set.
max(12, 13, 14)

# pow Function: Calculates an exponent, by raising its first argument to the power of the second argument.
pow(3, 2)
```

## Step-03: String Functions
```t
# Terraform Console
terraform console

# Trim Function: Removes the specified characters from the start and end of the given string.
trim("?!hello?!", "!?")

# Trimprefix Function: Removes the specified prefix from the start of the given string. If the string does not start with the prefix, the string is returned unchanged.
trimprefix("helloworld", "hello")
trimprefix("helloworld", "cat")

# Trimsuffix Function: Removes the specified suffix from the end of the given string.
trimsuffix("helloworld", "world")

# Trimspace Function: Removes any space characters from the start and end of the given string.
trimspace("  hello\n\n")

# Join Function: Produces a string by concatenating together all elements of a given list of strings with the given delimiter
join(separator, list)
join(", ", ["foo", "bar", "baz"])

# Split Function: Produces a list by dividing a given string at all occurrences of a given separator.
split(separator, string)
split(",", "foo,bar,baz")

# Upper Functon: Converts all cased letters in the given string to uppercase.
upper("hello")
```

## Step-04: Collection Functions
```t
# Terraform Console
terraform console

# Concat Function: Takes two or more lists and combines them into a single list.
concat(["a", ""], ["b", "c"])

# Contains Function: Determines whether a given list or set contains a given single value as one of its elements.
contains(list, value)
contains(["a", "b", "c"], "a")
contains(["a", "b", "c"], "d")

# Distinct Function: Takes a list and returns a new list with any duplicate elements removed.
distinct(["a", "b", "a", "c", "d", "b"])

# Length Function: determines the length of a given list, map, or string.
length("hello")
length(["a", "b"])
length(["a", "b"])

# Lookup Function: Retrieves the value of a single element from a map, given its key. If the given key does not exist, the given default value is returned instead.
lookup(map, key, default)
lookup({a="ay", b="bee"}, "a", "what?")
Web: 
lookup({"web" = ["10.0.1.0/24","10.0.2.0/24"], "app" = ["10.0.11.0/24","10.0.12.0/24"], "db" = ["10.0.21.0/24","10.0.22.0/24"]}, "web", ["10.0.51.0/24", "10.0.52.0/24"])

App: 
lookup({"web" = ["10.0.1.0/24","10.0.2.0/24"], "app" = ["10.0.11.0/24","10.0.12.0/24"], "db" = ["10.0.21.0/24","10.0.22.0/24"]}, "app", ["10.0.51.0/24", "10.0.52.0/24"])

DB:
lookup({"web" = ["10.0.1.0/24","10.0.2.0/24"], "app" = ["10.0.11.0/24","10.0.12.0/24"], "db" = ["10.0.21.0/24","10.0.22.0/24"]}, "db", ["10.0.51.0/24", "10.0.52.0/24"])

Default: 
lookup({"web" = ["10.0.1.0/24","10.0.2.0/24"], "app" = ["10.0.11.0/24","10.0.12.0/24"], "db" = ["10.0.21.0/24","10.0.22.0/24"]}, "abcd", ["10.0.51.0/24", "10.0.52.0/24"])



# Merge Function: Takes an arbitrary number of maps or objects, and returns a single map or object that contains a merged set of elements from all arguments.
merge({a="b", c="d"}, {e="f", c="z"})
merge({a="b"}, {a=[1,2], c="z"}, {d=3})
```

## Step-05: Encoding Functions
```t
# Terraform Console
terraform console

# base64decode Function: Takes a string containing a Base64 character sequence and returns the original string.
base64decode("SGVsbG8gV29ybGQ=")

# base64encode Function: Applies Base64 encoding to a string.
base64encode("Hello World")
```

## Step-06: FileSystem Functions
```t
# Terraform Console
terraform console

# File Function: Reads the contents of a file at the given path and returns them as a string.
file("${path.module}/files/hello.txt")

# fileexists Function: Determines whether a file exists at a given path.
fileexists("${path.module}/files/hello.txt")

# templatefile Function: Reads the file at the given path and renders its content as a template using a supplied set of template variables.
templatefile(path, vars)
```

## Step-07: templatefile & concat Function - Review TF Files
- **Reference Folder:** terraform-manifests
### c1-versions.tf
- No changes
### c2-variables.tf
- Added variabled package_name
```t
variable "package_name" {
  description = "Provide Package that need to be installed with user_data"
  type = string
  default = "httpd"
}
```
### c3-security-groups.tf
- No changes
### c4-ec2-instance.tf
- Added `user_data =  templatefile("user_data.tmpl", {package_name = var.package_name})`
```t
# Create EC2 Instance - Amazon2 Linux
resource "aws_instance" "my-ec2-vm" {
  ami           = data.aws_ami.amzlinux.id 
  instance_type = var.instance_type
  key_name      = "terraform-key"
  #user_data = file("apache-install.sh")  
  user_data =  templatefile("user_data.tmpl", {package_name = var.package_name})
  vpc_security_group_ids = [aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id]
  tags = {
    "Name" = "TF-Functions-Demo-1"
  }
}
```
### c5-outputs.tf
- Added output with `concat` function
```t
# Concat Security Group IDs in Output
output "security_group_ids" {
  value = concat([aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id])
}
/* Note: This will return the IDs of the security groups attached to your web 
instance as a list. You can use these lists as inputs in submodules.*/
```
### c6-ami-datasource.tf
- No changes
### user_data.tmpl
- Contains the shell script which will install the package provided from terraform variables. 
```sh
#! /bin/bash
sudo yum update -y
sudo yum install -y ${package_name}
sudo yum list installed | grep ${package_name} >> /tmp/package-installed-list.txt
```

## Step-08: Execute Terraform Commands
- Verify the installed packages
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Review Outputs for concat function
security_group_ids = [
  "sg-09f936287ddfc3b14",
  "sg-01f8a08bcbc4b9590",
]

# Connect to EC2 VM
ssh -i private-key/terraform-key ec2-user@<PUBLIC-IP>
cat /tmp/package-installed-list.txt
```

## Step-09: Clean-Up
```t
# Destroy Resources
terraform destory -auto-approve

# Delete Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## Step-10: Other Function Categories
- [Date and Time Functions](https://www.terraform.io/docs/language/functions/formatdate.html)
- [Hash and Crypto Functions](https://www.terraform.io/docs/language/functions/base64sha256.html)
- [IP Network Functions](https://www.terraform.io/docs/language/functions/cidrhost.html)
- [Type Conversion Functions](https://www.terraform.io/docs/language/functions/can.html)



## References
- [Terraform Functions](https://www.terraform.io/docs/language/functions/index.html)
