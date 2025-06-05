output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i koneksi-staging-key ubuntu@${module.ec2.bastion_public_ip}"
}

output "backend_ssh_command" {
  description = "SSH command to connect to the backend host through bastion"
  value       = "ssh -i koneksi-staging-key -o ProxyCommand='ssh -i koneksi-staging-key -W %h:%p ubuntu@${module.ec2.bastion_public_ip}' ubuntu@${module.ec2.backend_private_ip}"
}

output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = module.ec2.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host instance"
  value       = module.ec2.bastion_public_ip
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = module.ec2.bastion_security_group_id
}

output "backend_instance_id" {
  description = "ID of the backend host instance"
  value       = module.ec2.backend_instance_id
}

output "backend_private_ip" {
  description = "Private IP of the backend host instance"
  value       = module.ec2.backend_private_ip
}

output "backend_security_group_id" {
  description = "ID of the backend host security group"
  value       = module.ec2.backend_security_group_id
} 