resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "koneksi-staging-key"
  public_key = tls_private_key.generated.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.generated.private_key_pem
  sensitive = true
}

output "key_name" {
  value = aws_key_pair.generated.key_name
}