# AWS EC2 Instance Terraform Outputs
# Public EC2 Instances - Bastion Host

## ec2_bastion_public_instance_ids
output "ec2_bastion_public_instance_ids" {
  description = "List of IDs of instances"
  value       = aws_instance.ec2_public.id
}

## ec2_bastion_public_ip
output "ec2_bastion_public_ip" {
  description = "Elastic IP associated to the Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}

## ec2_bastion_private_ip
output "ec2_instance_private_instance_ids" {
  description = "List of IDs of instances"
  value       = aws_instance.ec2_private.id
}

## ec2_bastion_public_ip
output "ec2_inatance_private_ip" {
  description = "Elastic IP associated to the Bastion Host"
  value       = aws_instance.ec2_private.private_ip
}
