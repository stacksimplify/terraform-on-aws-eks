# Terraform Graph

## Step-01: Introduction
- The `terraform graph` command is used to generate a visual representation of either a configuration or execution plan
- The output is in the DOT format, which can be used by [GraphViz](http://www.graphviz.org/) to generate charts.

## Step-02: Run Terraform Graph command
```t
# Terraform Initialize
terraform init

# Terraform Graph
terraform graph > dot1
Observation: 
This command will output DOT format text and store in file dot1
```

## Step-03: Online Graphviz Viewers
- [Graphviz-Online](https://dreampuf.github.io/GraphvizOnline/)
- [Edotor-Online](https://edotor.net/)
- Copy and paste the text from `dot1` file generated in step-02 in these online Graphviz Viewers
- Review the output

## Step-04: Clean-Up
```t
# Delete .terraform files
rm -rf .terraform*
```

## Step-05: Other Options - Offline Graphviz Installer
### Step-05-01: Pre-requisite notes
- Graphviz is unstable on MacOS 
- Graphviz needs xcode to be installed on MacOS which consumes huge disk space.
- With that said, we are going to do this demo on Windows Machine
- We are going to use Windows 2019 EC2 instance created on AWS for the same. 

### Step-05-02: Create Windows 2019 VM ready
- Create Windows 2019 VM on AWS Cloud
- Disable Browser security settings in Server-Manager
- Install Google Chrome
- Download & Install Terraform CLI
- Set `Path` for Terraform CLI
- Copy `terraform-manifests` folder from `section-14: Terraform Graph` of the course to Windows VM


### Step-05-03: Install Graphviz on Windows VM
- [Download Graphviz](http://www.graphviz.org/download/)
- Install Graphviz 
```t
# Switch Directory
cd c:\graphviz-demo\terraform-manifests

# Terraform Initialize
terraform init

# Terraform Graph
terraform graph > dot1
Observation: 
This command will output DOT format text

# Terraform Graph in Image format
terraform graph | dot -Tsvg > graph.svg

# Verify
open graph.svg in browser
```


## References
- [Terraform Graph](https://www.terraform.io/docs/cli/commands/graph.html)