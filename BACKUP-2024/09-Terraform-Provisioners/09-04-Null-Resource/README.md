# Terraform Null Resource

## Step-01: Introduction
- Understand about [Null Provider](https://registry.terraform.io/providers/hashicorp/null/latest/docs)
- Understand about [Null Resource](https://www.terraform.io/docs/language/resources/provisioners/null_resource.html)
- Understand about [Time Provider](https://registry.terraform.io/providers/hashicorp/time/latest/docs)
- **Usecase:** Force a resource to update based on a changed null_resource
- Create `time_sleep` resource to wait for 90 seconds after EC2 Instance creation
- Create Null resource with required provisioners
  - File Provisioner: Copy apps/app1 folder to /tmp
  - Remote Exec Provisioner: Copy app1 folder from /tmp to /var/www/htnl
- Over the process we will learn about
  - null_resource
  - time_sleep resource
  - We will also learn how to Force a resource to update based on a changed null_resource using `timestamp function` and `triggers` in `null_resource`


## Step-02: Define null provider in Terraform Settings Block
- Update null provider info listed below in **c1-versions.tf**
```t
    null = {
      source = "hashicorp/null"
      version = "~> 3.0.0"
    }
```

## Step-03: Define Time Provider in Terraform Settings Block
- Update time provider info listed below in **c1-versions.tf**
```t
    time = {
      source = "hashicorp/time"
      version = "~> 0.6.0"
    }  
```

## Step-04: Create / Review the c4-ec2-instance.tf terraform configuration
### Step-04-01: Create Time Sleep Resource
- This resource will wait for 90 seconds after EC2 Instance creation.
- This wait time will give EC2 Instance to provision the Apache Webserver and create all its relevant folders
- Primarily if we want to copy static content we need Apache webserver static folder `/var/www/html`
```t
# Wait for 90 seconds after creating the above EC2 Instance 
resource "time_sleep" "wait_90_seconds" {
  depends_on = [aws_instance.my-ec2-vm]
  create_duration = "90s"
}
```
### Step-04-02: Create Null Resource
- Create Null resource with `triggers` with `timestamp()` function which will trigger for every `terraform apply`
- This `Null Resource` will help us to sync the static content from our local folder to EC2 Instnace as and when required.
- Also only changes will applied using only `null_resource` when `terraform apply` is run. In other words, when static content changes, how will we sync those changes to EC2 Instance using terraform - This is one simple solution.
- Primarily the focus here is to learn the following
  - null_resource
  - null_resource trigger
  - How trigger works based on timestamp() function ?
  - Provisioners in Null Resource
```t
# Sync App1 Static Content to Webserver using Provisioners
resource "null_resource" "sync_app1_static" {
  depends_on = [ time_sleep.wait_90_seconds ]
  triggers = {
    always-update =  timestamp()
  }

  # Connection Block for Provisioners to connect to EC2 Instance
  connection {
    type = "ssh"
    host = aws_instance.my-ec2-vm.public_ip 
    user = "ec2-user"
    password = ""
    private_key = file("private-key/terraform-key.pem")
  }  

 # Copies the app1 folder to /tmp
  provisioner "file" {
    source      = "apps/app1"
    destination = "/tmp"
  }

# Copies the /tmp/app1 folder to Apache Webserver /var/www/html directory
  provisioner "remote-exec" {
    inline = [
      "sudo cp -r /tmp/app1 /var/www/html"
    ]
  }
}
```

## Step-05: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Format
terraform fmt

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify
ssh -i private-key/terraform-key.pem ec2-user@<PUBLIC-IP>
ls -lrt /tmp
ls -lrt /tmp/app1
ls -lrt /var/www/html
ls -lrt /var/www/html/app1
http://<public-ip>/app1/file1.html
http://<public-ip>/app1/file2.html
```

## Step-06: Create new file locally in app1 folder
- Create a new file named `file3.html`
- Also updated `file1.html` with some additional info
- **file3.html**
```html
<h1>>App1 File3</h1
```
- **file1.html**
```html
<h1>>App1 File1 - Updated</h1
```

## Step-07: Execute Terraform plan and apply commands
```t
# Terraform Plan
terraform plan
Observation: You should see changes for "null_resource.sync_app1_static" because trigger will have new timestamp when you fired the terraform plan command

# Terraform Apply
terraform apply -auto-approve

# Verify
chmod 400 private-key/terraform-key.pem
ssh -i private-key/terraform-key.pem ec2-user@<PUBLIC-IP>
ls -lrt /tmp
ls -lrt /tmp/app1
ls -lrt /var/www/html
ls -lrt /var/www/html/app1
http://<public-ip>/app1/file1.html
http://<public-ip>/app1/file3.html
```

## Step-08: Clean-Up Resources & local working directory
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Terraform files 
rm -rf .terraform*
rm -rf terraform.tfstate*
```



## References
- [Resource: time_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)
- [Time Provider](https://registry.terraform.io/providers/hashicorp/time/latest/docs)
