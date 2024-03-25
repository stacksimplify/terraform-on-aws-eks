# Terraform Foundational Policies using Sentinel

## Step-01: Introduction
- [Terraform Foundational Policies Library](https://github.com/hashicorp/terraform-foundational-policies-library)
- This repository contains a library of policies that can be used within Terraform Cloud to accelerate your adoption of policy as code.
- This is pre-built sentinel policies provided by Terraform

## Step-02: Review sentinel.hcl
- [Terraform Foundational Policies using Sentinel](https://github.com/hashicorp/terraform-foundational-policies-library)
- [Terraform Sentinel AWS CIS Networking Policies](https://github.com/hashicorp/terraform-foundational-policies-library/tree/master/cis/aws/networking)
- **Folder Name:** terraform-sentinel-cis-policies
```t
policy "aws-cis-4.1-networking-deny-public-ssh-acl-rules" {
  source = "https://raw.githubusercontent.com/hashicorp/terraform-foundational-policies-library/master/cis/aws/networking/aws-cis-4.1-networking-deny-public-ssh-acl-rules/aws-cis-4.1-networking-deny-public-ssh-acl-rules.sentinel"
  enforcement_level = "advisory"
}

policy "aws-cis-4.2-networking-deny-public-rdp-acl-rules" {
  source = "https://raw.githubusercontent.com/hashicorp/terraform-foundational-policies-library/master/cis/aws/networking/aws-cis-4.2-networking-deny-public-rdp-acl-rules/aws-cis-4.2-networking-deny-public-rdp-acl-rules.sentinel"
  enforcement_level = "advisory"
}

policy "aws-cis-4.3-networking-restrict-all-vpc-traffic-acl-rules" {
  source = "https://raw.githubusercontent.com/hashicorp/terraform-foundational-policies-library/master/cis/aws/networking/aws-cis-4.3-networking-restrict-all-vpc-traffic-acl-rules/aws-cis-4.3-networking-restrict-all-vpc-traffic-acl-rules.sentinel"
  enforcement_level = "advisory"
}
```

## Step-03: Copy Sentinel CIS Policies to terraform-sentinel-policies git repo
- Copy folder `terraform-sentinel-cis-policies` to Local git repository `terraform-sentinel-policies`
- **Check-In code to Remote Repository**
```t
# GIT Status
git status

# Git Local Commit
git add .
git commit -am "Sentinel CIS Policies Added in new folder"

# Push to Remote Repository
git push

# Verify the same on Remote Repository
https://github.com/stacksimplify/terraform-sentinel-policies.git
```

## Step-04: Add new Sentinel Policy Set in Terraform Cloud
- Go to Terraform Cloud -> Organization (hcta-demo1) -> Settings -> Policy Sets
- Click on **Connect a new Policy Set**
- Use existing VCS connection from previous section **github-terraform-modules** which we created using OAuth App concept
- **Choose Repository:** terraform-sentinel-policies.git
- **Name:** terraform-sentinel-cis-policies
- **Description:** terraform sentinel cis-policies
- **Policies Path:** terraform-sentinel-cis-policies
- **Scope of Policies:** Policies enforced on selected workspaces
- **Workspaces:** terraform-cloud-demo1
- Click on **Connect Policy Set**

## Step-05: Review our first Terraform Cloud Workspace
- Go to Terraform Cloud -> Organization (hcta-demo1) -> workspace (terraform-cloud-demo1)
- Queue Plan -> CIS-Policy-Test-1
- Verify the following
  - Plan
  - Cost Estimate
  - Policy Check:  Verify what all passed and failed
- Finally, Disacrd the Run

