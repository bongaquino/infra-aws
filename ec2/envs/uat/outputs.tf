output "uat_bastion_instance_id" {
  description = "ID of the UAT bastion instance"
  value       = aws_instance.uat_bastion.id
}

output "uat_bastion_public_ip" {
  description = "Public IP of the UAT bastion instance"
  value       = aws_instance.uat_bastion.public_ip
}

output "uat_bastion_private_ip" {
  description = "Private IP of the UAT bastion instance"
  value       = aws_instance.uat_bastion.private_ip
}

output "uat_bastion_ssh_command" {
  description = "SSH command to connect to the UAT bastion"
  value       = "ssh -i koneksi-uat-key ubuntu@${aws_instance.uat_bastion.public_ip}"
} 