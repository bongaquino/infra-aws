output "staging_backend_instance_id" {
  description = "ID of the staging backend instance"
  value       = aws_instance.staging_backend.id
}

output "staging_backend_public_ip" {
  description = "Public IP of the staging backend instance"
  value       = aws_instance.staging_backend.public_ip
}

output "staging_backend_private_ip" {
  description = "Private IP of the staging backend instance"
  value       = aws_instance.staging_backend.private_ip
}

output "staging_ssh_command" {
  description = "SSH command to connect to the staging backend"
  value       = "ssh -i koneksi-staging-key ubuntu@${aws_instance.staging_backend.public_ip}"
} 