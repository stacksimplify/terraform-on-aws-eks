# Terraform State Commands

## Step-01: Introduction
- Terraform Commands
  - terraform show
  - terraform refresh
  - terraform plan (internally calls refresh)
  - terraform state
  - terraform force-unlock   
  - terraform taint
  - terraform untaint
  - terraform apply target command  

## Pre-requisite: c1-versions.tf
- Update your backend block with your bucket name, key and region
- Also update your dynamodb table name
```t
# Terraform Block
terraform {
  required_version = "~> 0.14" # which means any version equal & above 0.14 like 0.15, 0.16 etc and < 1.xx
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-stacksimplify"
    key    = "statecommands/terraform.tfstate"
    region = "us-east-1" 

    # Enable during Step-09     
    # For State Locking
    dynamodb_table = "terraform-dev-state-table"    
    
  }
}
```  

## Step-02: Terraform Show Command to review Terraform plan files
- The `terraform show` command is used to provide human-readable output from a state or plan file. 
- This can be used to inspect a plan to ensure that the planned operations are expected, or to inspect the current state as
- Terraform plan output files are binary files. We can read them using `terraform show` command
```t
# Initialize Terraform
terraform init

# Create Plan 
terraform plan -out=v1plan.out

# Read the plan 
terraform show v1plan.out

# Read the plan in json format
terraform show -json v1plan.out
```

## Step-03: Terraform Show command to Read State files
- By default, in the working directory if we have `terraform.tfstate` file, when we provide the command `terraform show` it will read the state file automatically and display output.  
```t
# Terraform Show
terraform show
Observation: It should say "No State" because we will still didn't create any resources yet and no state file in current working directory

# Create Resources
terraform apply -auto-approve

# Terraform Show 
terraform show
Observation: It should display the state file
```

## Step-04: Understand terraform refresh in detail
- This commands comes under **Terraform Inspecting State**
- Understanding `terraform refresh` clears a lot of doubts in our mind and terraform state file and state feature
- The terraform refresh command is used to reconcile the state Terraform knows about (via its state file) with the real-world infrastructure. 
- This can be used to detect any drift from the last-known state, and to update the state file.
- This does not modify infrastructure, but does modify the state file. If the state is changed, this may cause changes to occur during the next plan or apply.
- **terraform refresh:** Update local state file against real resources in cloud
- **Desired State:** Local Terraform Manifest (All *.tf files)
- **Current State:**  Real Resources present in your cloud
- **Command Order of Execution:** refresh, plan, make a decision, apply
- Why? Lets understand that in detail about this order of execution
### Step-04-01: Add a new tag to EC2 Instance using AWS Management Console
```t
"demotag" = "refreshtest"
```

### Step-04-02: Execute terraform plan  
- You should observe no changes to local state file because plan does the comparison in memory 
- Verify S3 Bucket - no update to tfstate file about the change 
```t
# Execute Terraform plan
terraform plan 
```
### Step-04-03: Execute terraform refresh 
- You should see terraform state file updated with new demo tag
```
# Execute terraform refresh
terraform refresh

# Review terraform state file
1) terraform show
2) Also verify S3 bucket, new version of terraform.tfstate file will be created
```
### Step-04-04: Why you need to the execution in this order (refresh, plan, make a decision, apply) ?
- There are changes happened in your infra manually and not via terraform.
- Now decision to be made if you want those changes or not.
- **Choice-1:** If you dont want those changes proceed with terraform apply so manual changes we have done on our cloud EC2 Instance will be removed.
- **Choice-2:** If you want those changes, refer `terraform.tfstate` file about changes and embed them in your terraform manifests (example: c4-ec2-instance.tf) and proceed with flow (referesh, plan, review execution plan and apply)

### Step-04-05: I picked choice-2, so i will update the tags in c4-ec2-instance.tf
- Update in c4-ec2-instance.tf
```t
  tags = {
    "Name" = "amz-linux-vm"
    "demotag" = "refreshtest"
  }
```
### Step-04-06: Execute the commands to make our manual change official in terraform manifests and tfstate files perspective  
```t
# Terraform Refresh
terraform refresh

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```


## Step-05: Terraform State Command
### Step-05-01: Terraform State List and Show commands
- These two commands comes under **Terraform Inspecting State**
- **terraform state list:**  This command is used to list resources within a Terraform state.
- **terraform  state show:** This command is used to show the attributes of a single resource in the Terraform state.
```t
# List Resources from Terraform State
terraform state list

# Show the attributes of a single resource from Terraform State
terraform  state show data.aws_ami.amzlinux
terraform  state show aws_instance.my-ec2-vm
```
### Step-05-02: Terraform State mv command
- This commands comes under **Terraform Moving Resources**
- This command will move an item matched by the address given to the
 destination address. 
- This command can also move to a destination address
 in a completely different state file
- Very dangerous command
- Very advanced usage command
- Results will be unpredictable if concept is not clear about terraform state files mainly  desired state and current state.  
- Try this in production environments, only  when everything worked well in lower environments. 
```t
# Terraform List Resources
terraform state list

# Terraform State Move Resources to different name
terraform state mv -dry-run aws_instance.my-ec2-vm aws_instance.my-ec2-vm-new 
terraform state mv aws_instance.my-ec2-vm aws_instance.my-ec2-vm-new 
ls -lrta

Observation: 
1) It should create a backup file of terraform.tfstate as something like this "terraform.tfstate.1611929587.backup"
1) It renamed the name of "my-ec2-vm" in state file to "my-ec2-vm-new". 
2) Run terraform plan and observe what happens in next run of terraform plan and apply
-----------------------------
# WRONG APPROACH 
-----------------------------
# WRONG APPROACH OF MOVING TO TERRAFORM PLAN AND APPLY AFTER ABOVE CHANGE terraform state mv CHANGE
# WE NEED TO UPDATE EQUIVALENT RESOURCE in terraform manifests to match the same new name. 

# Terraform Plan
terraform plan
Observation: It will show "Plan: 1 to add, 0 to change, 1 to destroy."
1 to add: New EC2 Instance will be added
1 to destroy: Old EC2 instance will be destroyed

DON'T DO TERRAFORM APPLY because it shows make changes. Nothing changed other than state file local naming of a resource. Ideally nothing on current state (real cloud environment should not change due to this)
-----------------------------

-----------------------------
# RIGHT APPROACH
-----------------------------
Update "c3-ec2-instance.tf"
Before: resource "aws_instance" "my-ec2-vm" {
After: resource "aws_instance" "my-ec2-vm-new" {  

Update all references of this resources in your terraform manifests
Update c5-outputs.tf
Before: value = aws_instance.my-ec2-vm.public_ip
After: value = aws_instance.my-ec2-vm-new.public_ip

Before: value = aws_instance.my-ec2-vm.public_dns
After: value = aws_instance.my-ec2-vm-new.public_dns

Now run terraform plan and you should see no changes to Infra

# Terraform Plan
terraform plan
Observation: 
1) Message-1: No changes. Infrastructure is up-to-date
2) Message-2: This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
 
```
### Step-05-03: Terraform State rm command
- This commands comes under **Terraform Moving Resources**
- The `terraform state rm` command is used to remove items from the Terraform state. 
- This command can remove single resources, single instances of a resource, entire modules, and more.
```t
# Terraform List Resources
terraform state list

# Remove Resources from Terraform State
terraform state rm -dry-run aws_instance.my-ec2-vm-new
terraform state rm aws_instance.my-ec2-vm-new
Observation: 
1) Firstly takes backup of current state file before removing (example: terraform.tfstate.1611930284.backup)
2) Removes it from terraform.tfstate file

# Terraform Plan
terraform plan
Observation: It will tell you that resource is not in state file but same is present in your terraform manifests (03-ec2-instace.tf - DESIRED STATE). Do you want to re-create it?
This will re-create new EC2 instance excluding one created earlier and running

Make a  Choice
-------------
Choice-1: You want this resource to be running on cloud but should not be managed by terraform. Then remove its references in terraform manifests(DESIRED STATE). So that the one running in AWS cloud (current infra) this instance will be independent of terraform. 
Choice-2: You want a new resource to be created without deleting other one (non-terraform managed resource now in current state). Run terraform plan and apply
LIKE THIS WE NEED TO MAKE DECISIONS ON WHAT WOULD BE OUR OUTCOME OF REMOVING A RESOURCE FROM STATE.

PRIMARY REASON for this is command is that respective resource need to be removed from as terraform managed. 

# Run Terraform Plan
terraform plan

# Run Terraform Apply
terraform apply 
```

# Step-05-04: Terraform State replace-provider command
- This commands comes under **Terraform Moving Resources**
- [Terraform State Replace Provider](https://www.terraform.io/docs/cli/commands/state/replace-provider.html)


### Step-05-05: Terraform State pull / push command
- This command comes under **Terraform Disaster Recovery Concept**
- **terraform state pull:** 
  - The `terraform state pull` command is used to manually download and output the state from remote state.
  - This command also works with local state.
  - This command will download the state from its current location and output the raw format to stdout.
- **terraform state push:** The `terraform state push` command is used to manually upload a local state file to remote state. 

```t
# Other State Commands (Pull / Push)
terraform state pull
terraform state push
```

## Step-06: Terraform force-unlock command
- This command comes under **Terraform Disaster Recovery Concept**
- Manually unlock the state for the defined configuration.
- This will not modify your infrastructure. 
- This command removes the lock on the state for the current configuration. 
- The behavior of this lock is dependent on the backend (aws s3 with dynamodb for state locking etc) being used. 
- **Important Note:** Local state files cannot be unlocked by another process.
```t
# Manually Unlock the State
terraform force-unlock LOCK_ID
```

## Step-07: Terraform taint & untaint commands
-  These commands comes under **Terraform Forcing Re-creation of Resources**
- When a resource declaration is modified, Terraform usually attempts to update the existing resource in place (although some changes can require destruction and re-creation, usually due to upstream API limitations).
- **Example:** A virtual machine that configures itself with cloud-init on startup might no longer meet your needs if the cloud-init configuration changes.
- **terraform taint:** The `terraform taint` command manually marks a Terraform-managed resource as tainted, forcing it to be destroyed and recreated on the next apply.
- **terraform untaint:** 
  - The terraform untaint command manually unmarks a Terraform-managed resource as tainted, restoring it as the primary instance in the state. 
  - This reverses either a manual terraform taint or the result of provisioners failing on a resource.
  - This command will not modify infrastructure, but does modify the state file in order to unmark a resource as tainted.
```t
# List Resources from state
terraform state list

# Taint a Resource
terraform taint <RESOURCE_NAME_IN_TERRAFORM_LOCALLY>
terraform taint aws_instance.my-ec2-vm-new

# Terraform Plan
terraform plan
Observation: 
Message: "-/+ destroy and then create replacement"

# Untaint a Resource
terraform untaint <RESOURCE_NAME_IN_TERRAFORM_LOCALLY>
terraform untaint aws_instance.my-ec2-vm-new

# Terraform Plan
terraform plan
Observation: 
Message: "No changes. Infrastructure is up-to-date."
```


## Step-08: Terraform Resource Targeting - Plan, Apply (-target) Option
- The `-target` option can be used to focus Terraform's attention on only a subset of resources. 
- [Terraform Resource Targeting](https://www.terraform.io/docs/cli/commands/plan.html#resource-targeting)
- This targeting capability is provided for exceptional circumstances, such as recovering from mistakes or working around Terraform limitations.
-  It is not recommended to use `-target` for routine operations, since this can lead to undetected configuration drift and confusion about how the true state of resources relates to configuration.
- Instead of using `-target` as a means to operate on isolated portions of very large configurations, prefer instead to break large configurations into several smaller configurations that can each be independently applied.
```t
# Lets make two changes
Change-1: Add new tag in c4-ec2-instance.tf
    "target" = "Target-Test-1"
Change-2: Add additional inbound rule in "vpc-web" security group for port 8080
  ingress {
    description = "Allow Port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
Change-3: Add new EC2 Resource  
# New VM
resource "aws_instance" "my-demo-vm" {
  ami           = data.aws_ami.amzlinux.id 
  instance_type = var.instance_type
  tags = {
    "Name" = "demo-vm1"
  }
}

# List Resources from state
terraform state list

# Terraform plan
terraform plan -target=aws_instance.my-ec2-vm-new
Observation:
0) Message: "Plan: 0 to add, 2 to change, 0 to destroy."
1) It is updating Change-1 because we are targeting that resource "aws_instance.my-ec2-vm-new"
2) It is updating change-2 "vpc-web" because its a dependent resource for "aws_instance.my-ec2-vm-new"
3) It is not touching the new resource which we are creating now. It will be in terraform configuration but not getting provisioned when we are using -target

# Terraform Apply
terraform apply -target=aws_instance.my-ec2-vm-new

```

## Step-09: Terraform Destroy & Clean-Up
```t
# Destory Resources
terraform destroy -auto-approve

# Clean-Up Files
rm -rf .terraform*
rm -rf v1plan.out

# Kalyan - Not to forgot to change these things after Recording
# Ensure below two lines are in commented state in c4-ec2-instance.tf
1) This is required for students demo for this entire section to implement in a step by step manner from beginning
    #"demotag" = "refreshtest"  # Enable during Step-04-05
    # "target" = "Target-Test-1" # Enable during step-08
2) Rename the local name for EC2 Instance from "my-ec2-vm-new" to "my-ec2-vm"
Changed during step 05-02: aws_instance.my-ec2-vm-new
Roll back for the students to have a seamless demo

3) Roll back changes you have made in step-08
3.1: New tag in EC2 Instance
3.2: New rule in vpc-web security group
3.3: New EC2 Instance resource in c4-ec2-instance.tf
```

## References
- [Terraform State Command](https://www.terraform.io/docs/cli/commands/state/index.html)
- [Terraform Inspect State](https://www.terraform.io/docs/cli/state/inspect.html)
- [Terraform Moving Resources](https://www.terraform.io/docs/cli/state/move.html)
- [Terraform Disaster Recovery](https://www.terraform.io/docs/cli/state/recover.html)
- [Terraform Taint](https://www.terraform.io/docs/cli/state/taint.html)
- [Terraform State](https://www.terraform.io/docs/language/state/index.html)
- [Manipulating Terraform State](https://www.terraform.io/docs/cli/state/index.html)
- [Additional Reference](https://www.hashicorp.com/blog/detecting-and-managing-drift-with-terraform)
