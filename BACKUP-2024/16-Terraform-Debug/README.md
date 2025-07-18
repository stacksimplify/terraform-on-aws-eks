# Terraform Debug

## Step-01: Introduction
- Learn about Terraform Debug
- TF_LOG & TF_LOG_PATH
- TF_LOG - Allowed Values or Desired Log Levels
- **TRACE:** Very detailed verbosity, shows every step taken by Terraform and produces enormous outputs with internal logs.
- **DEBUG:** describes what happens internally in a more concise way compared to TRACE.
- **ERROR:** shows errors that prevent Terraform from continuing.
- **WARN:** logs warnings, which may indicate misconfiguration or mistakes, but are not critical to execution
- **INFO:** shows general, high-level messages about the execution process.
- **Important Note:** 


## Step-02: Setup Trace logging in Terraform
```t
# Terrafrom Trace Log Settings
export TF_LOG=TRACE
export TF_LOG_PATH="terraform-trace.log"
echo $TF_LOG
echo $TF_LOG_PATH

# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Terraform Destroy
terraform destroy -auto-approve

# Clean-Up
rm -rf .terraform*
rm -rf terraform.tfstate*
rm terraform-trace.log
```


## Step-03: Setup these Environment Variables permanently in your desktops
### Linux Bash
- Open your `.bashrc` which is located in your $home directory 
```t
# Linux Bash
cd $HOME
vi .bashrc

# Terraform log settings
export TF_LOG=TRACE
export TF_LOG_PATH="terraform-trace.log"

# Verify after saving the file in new terminal 
$ echo $TF_LOG
TRACE
$ echo $TF_LOG_PATH
terraform-trace.log
```
### Windows Powershell
- Setup using Powershell profile
- Open `$profile` command in a PowerShell
- Once that file is opened add the following lines.
- Now close and reopen the console and type the following to verify that it worked.
```t
# Windows Powershell - Terraform log settings
$env:TF_LOG="TRACE"
$env:TF_LOG_PATH="terraform.txt"

# Open new powershell window & Verify
echo $env:TF_LOG
echo $env:TF_LOG_PATH
```
### MAC OS
- Update the values in `.bash_profile` at the end of file
```t
# MAC OS
cd $HOME
vi .bash_profile

# Terraform log settings
export TF_LOG=TRACE
export TF_LOG_PATH="terraform-trace.log"

# Verify after saving the file in new terminal 
$ echo $TF_LOG
TRACE
$ echo $TF_LOG_PATH
terraform-trace.log
```

## Step-04: Terraform Crash Log
- If Terraform ever crashes (a "panic" in the Go runtime), it saves a log file with the debug logs from the session as well as the panic message and backtrace to `crash.log`.
- Generally speaking, this log file is meant to be passed along to the developers via a GitHub Issue. 
- As a user, you're not required to dig into this file.
- [How to read a crash log?](https://www.terraform.io/docs/internals/debugging.html#interpreting-a-crash-log)