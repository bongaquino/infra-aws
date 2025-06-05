# Generate private key
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh

  tags = var.tags
}

# Save private key to file
resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = var.private_key_path
  file_permission = "0400"
  directory_permission = "0700"
} 