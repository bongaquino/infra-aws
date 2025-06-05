output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host instance"
  value       = aws_eip.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = data.aws_security_group.public.id
}

output "backend_instance_id" {
  description = "ID of the backend host instance"
  value       = aws_instance.backend.id
}

output "backend_private_ip" {
  description = "Private IP of the backend host instance"
  value       = aws_instance.backend.private_ip
}

output "backend_public_ip" {
  description = "Public IP of the backend host instance"
  value       = aws_eip.backend.public_ip
}

output "backend_security_group_id" {
  description = "ID of the backend host security group"
  value       = data.aws_security_group.private.id
} 