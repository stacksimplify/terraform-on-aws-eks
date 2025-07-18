# Terraform Provisioners

## Step-00: Provisioner Concepts
- Generic Provisioners
  - file
  - local-exec
  - remote-exec
- Provisioner Timings
  - Creation-Time Provisioners (by default)
  - Destroy-Time Provisioners  
- Provisioner Failure Behavior
  - continue
  - fail
- Provisioner Connections
- Provisioner Without a Resource  (Null Resource)

## Pre-requisites
- Create a EC2 Key pain with name `terraform-key` and copy the `terraform-key.pem` file in the folder `private-key` in `terraform-manifest` folder
- Connection Block for provisioners uses this to connect to newly created EC2 instance to copy files using `file provisioner`, execute scripts using `remote-exec provisioner`

## Step-01: Introduction
- Understand about File Provisioners
- Create Provisioner Connections block required for File Provisioners
- We will also discuss about **Creation-Time Provisioners (by default)**
- Understand about Provisioner Failure Behavior
  - continue
  - fail
- Discuss about Destroy-Time Provisioners    


## Step-02: File Provisioner & Connection Block
- **Referencec Sub-Folder:** terraform-manifests
- Understand about file provisioner & Connection Block
- **Connection Block**
  - We can have connection block inside resource block for all provisioners 
  -[or] We can have connection block inside a provisioner block for that respective provisioner
- **Self Object**
  - **Important Technical Note:** Resource references are restricted here because references create dependencies. Referring to a resource by name within its own block would create a dependency cycle.
  - Expressions in provisioner blocks cannot refer to their parent resource by name. Instead, they can use the special **self object.**
  - The **self object** represents the provisioner's parent resource, and has all of that resource's attributes. 
```t
  # Connection Block for Provisioners to connect to EC2 Instance
  connection {
    type = "ssh"
    host = self.public_ip # Understand what is "self"
    user = "ec2-user"
    password = ""
    private_key = file("private-key/terraform-key.pem")
  }  
```

## Step-03: Create multiple provisioners of various types
- **Creation-Time Provisioners:** 
- By default, provisioners run when the resource they are defined within is created. 
- Creation-time provisioners are only run during creation, not during updating or any other lifecycle. 
- They are meant as a means to perform bootstrapping of a system.
- If a creation-time provisioner fails, the resource is marked as tainted. 
- A tainted resource will be planned for destruction and recreation upon the next terraform apply.
- Terraform does this because a failed provisioner can leave a resource in a semi-configured state. 
- Because Terraform cannot reason about what the provisioner does, the only way to ensure proper creation of a resource is to recreate it. This is tainting.
- You can change this behavior by setting the on_failure attribute, which is covered in detail below.

```t

 # Copies the file-copy.html file to /tmp/file-copy.html
  provisioner "file" {
    source      = "apps/file-copy.html"
    destination = "/tmp/file-copy.html"
  }

  # Copies the string in content into /tmp/file.log
  provisioner "file" {
    content     = "ami used: ${self.ami}" # Understand what is "self"
    destination = "/tmp/file.log"
  }

  # Copies the app1 folder to /tmp - FOLDER COPY
  provisioner "file" {
    source      = "apps/app1"
    destination = "/tmp"
  }

  # Copies all files and folders in apps/app2 to /tmp - CONTENTS of FOLDER WILL BE COPIED
  provisioner "file" {
    source      = "apps/app2/" # when "/" at the end is added - CONTENTS of FOLDER WILL BE COPIED
    destination = "/tmp"
  }
 # Copies the file-copy.html file to /tmp/file-copy.html
  provisioner "file" {
    source      = "apps/file-copy.html"
    destination = "/tmp/file-copy.html"
  }

  # Copies the string in content into /tmp/file.log
  provisioner "file" {
    content     = "ami used: ${self.ami}" # Understand what is "self"
    destination = "/tmp/file.log"
  }

  # Copies the app1 folder to /tmp - FOLDER COPY
  provisioner "file" {
    source      = "apps/app1"
    destination = "/tmp"
  }

  # Copies all files and folders in apps/app2 to /tmp - CONTENTS of FOLDER WILL BE COPIED
  provisioner "file" {
    source      = "apps/app2/" # when "/" at the end is added - CONTENTS of FOLDER WILL BE COPIED
    destination = "/tmp"
  }
```

## Step-04: Create Resources using Terraform commands

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

# Verify - Login to EC2 Instance
chmod 400 private-key/terraform-key.pem 
ssh -i private-key/terraform-key.pem ec2-user@IP_ADDRESSS_OF_YOUR_VM
ssh -i private-key/terraform-key.pem ec2-user@54.197.54.126
Verify /tmp for all files copied
cd /tmp
ls -lrta /tmp

# Clean-up
terraform destroy -auto-approve
rm -rf terraform.tfsate*
```

## Step-05: Failure Behavior: Understand Decision making when provisioner fails (continue / fail)
- By default, provisioners that fail will also cause the Terraform apply itself to fail. The on_failure setting can be used to change this. The allowed values are:
  - **continue:** Ignore the error and continue with creation or destruction.
  - **fail:** (Default Behavior) Raise an error and stop applying (the default behavior). If this is a creation provisioner, taint the resource.  
- Try copying a file to Apache static content folder "/var/www/html" using file-provisioner
- This will fail because, the user you are using to copy these files is "ec2-user" for amazon linux vm. This user don't have access to folder "/var/www/html/" top copy files. 
- We need to use sudo to do that. 
- All we know is we cannot copy it directly, but we know we have already copied this file in "/tmp" using file provisioner
- **Try two scenarios**
  - No `on_failure` attribute (Same as `on_failure = fail`) - default what happens It will Raise an error and stop applying. If this is a creation provisioner, it will taint the resource.
  - When `on_failure = continue`, will continue creating resources
  - **Verify:**  Verify `terraform.tfstate` for  `"status": "tainted"`
```t
# Test-1: Without on_failure attribute which will fail terraform apply
 # Copies the file-copy.html file to /var/www/html/file-copy.html
  provisioner "file" {
    source      = "apps/file-copy.html"
    destination = "/var/www/html/file-copy.html"
   }
###### Verify:  Verify terraform.tfstate for  "status": "tainted"

# Test-2: With on_failure = continue
 # Copies the file-copy.html file to /var/www/html/file-copy.html
  provisioner "file" {
    source      = "apps/file-copy.html"
    destination = "/var/www/html/file-copy.html"
    on_failure  = continue 
   }
###### Verify:  Verify terraform.tfstate for  "status": "tainted"  
```
```t

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify
Login to EC2 Instance
Verify /tmp, /var/www/html for all files copied
```

## Step-06: Clean-Up Resources & local working directory
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Terraform files 
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## Step-07: Destroy Time Provisioners
- Discuss about this concept
- [Destroy Time Provisioners](https://www.terraform.io/docs/language/resources/provisioners/syntax.html#destroy-time-provisioners)
- Inside a provisioner when you add this statement `when    = destroy` it will provision this during the resource destroy time
```t
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    when    = destroy 
    command = "echo 'Destroy-time provisioner'"
  }
}
```