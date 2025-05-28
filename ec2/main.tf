provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "bastion" {
  ami                    = "ami-07945fd9edc6f05f4"
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ubuntu
              sudo chmod 0440 /etc/sudoers.d/ubuntu
              EOF

  tags = {
    Name = "${var.project}-${var.environment}-bastion"
  }
}

output "instance_id" {
  value = aws_instance.bastion.id
}

output "public_ip" {
  value = aws_instance.bastion.public_ip
} 