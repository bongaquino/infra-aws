# =============================================================================
# EC2 Instance
# =============================================================================
resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.public_sg_id]
  key_name               = var.key_name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Elastic IP
# =============================================================================
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-eip"
  })

  lifecycle {
    prevent_destroy = true
  }
} 