resource "tls_private_key" "staging" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "staging" {
  key_name   = "koneksi-staging-key"
  public_key = tls_private_key.staging.public_key_openssh
}

output "staging_private_key_pem" {
  description = "PEM-encoded private key for staging EC2 access. Save this securely."
  value       = tls_private_key.staging.private_key_pem
  sensitive   = true
}

output "staging_key_name" {
  value = aws_key_pair.staging.key_name
} 