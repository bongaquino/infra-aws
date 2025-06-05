# =============================================================================
# Terraform Configuration
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# EC2 Instance
# =============================================================================
resource "aws_instance" "main" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]
  
  key_name = var.key_name
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
    
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-root-volume"
    })
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  monitoring    = var.monitoring
  ebs_optimized = var.ebs_optimized
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Security Group
# =============================================================================
resource "aws_security_group" "instance" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
    description     = "SSH from bastion"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
}

# =============================================================================
# EBS Volume (if enabled)
# =============================================================================
resource "aws_ebs_volume" "data" {
  count = var.enable_data_volume ? 1 : 0
  
  availability_zone = aws_instance.main.availability_zone
  size             = var.data_volume_size
  type             = var.data_volume_type
  encrypted        = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-data-volume"
  })
}

resource "aws_volume_attachment" "data" {
  count = var.enable_data_volume ? 1 : 0
  
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data[0].id
  instance_id = aws_instance.main.id
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.name_prefix}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  
  dimensions = {
    InstanceId = aws_instance.main.id
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "${var.name_prefix}-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 memory utilization"
  
  dimensions = {
    InstanceId = aws_instance.main.id
  }
  
  tags = var.tags
} 