# Resource: Security Group - Allow Inbound NFS Traffic from EKS VPC CIDR to EFS File System
resource "aws_security_group" "efs_allow_access" {
  name        = "efs-allow-nfs-from-eks-vpc"
  description = "Allow Inbound NFS Traffic from EKS VPC CIDR"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    description      = "Allow Inbound NFS Traffic from EKS VPC CIDR to EFS File System"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [data.terraform_remote_state.eks.outputs.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nfs_from_eks_vpc"
  }
}


# Resource: EFS File System
resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "efs-demo"
  tags = {
    Name = "efs-demo"
  }
}

# Resource: EFS Mount Target
resource "aws_efs_mount_target" "efs_mount_target" {
  #for_each = toset(module.vpc.private_subnets)
  count = 2
  file_system_id = aws_efs_file_system.efs_file_system.id
  subnet_id      = data.terraform_remote_state.eks.outputs.private_subnets[count.index]
  security_groups = [ aws_security_group.efs_allow_access.id ]
}


# EFS File System ID
output "efs_file_system_id" {
  description = "EFS File System ID"
  value = aws_efs_file_system.efs_file_system.id 
}

output "efs_file_system_dns_name" {
  description = "EFS File System DNS Name"
  value = aws_efs_file_system.efs_file_system.dns_name
}

# EFS Mounts Info
output "efs_mount_target_id" {
  description = "EFS File System Mount Target ID"
  value = aws_efs_mount_target.efs_mount_target[*].id 
}

output "efs_mount_target_dns_name" {
  description = "EFS File System Mount Target DNS Name"
  value = aws_efs_mount_target.efs_mount_target[*].mount_target_dns_name 
}

output "efs_mount_target_availability_zone_name" {
  description = "EFS File System Mount Target availability_zone_name"
  value = aws_efs_mount_target.efs_mount_target[*].availability_zone_name 
}
