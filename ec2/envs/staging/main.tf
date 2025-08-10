provider "aws" {
  region = "ap-southeast-1"
}

# Staging Backend Instance - matches AWS reality
resource "aws_instance" "staging_backend" {
  ami           = "ami-01938df366ac2d954"  # Real AMI from AWS
  instance_type = "c6a.xlarge"            # Real instance type from AWS
  key_name      = "bongaquino-staging-key"   # Real key from AWS
  subnet_id     = "subnet-07fd670efb8a816db"  # Public subnet
  vpc_security_group_ids = ["sg-066e2c5f4bfdab814"]  # Real security group from AWS
  
  iam_instance_profile = "bongaquino-staging-ec2-ssm-profile"  # Real IAM profile from AWS
  
  # Match real configuration
  monitoring                 = false
  ebs_optimized             = true
  source_dest_check         = true
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 40  # Match real AWS volume size
    delete_on_termination = true
    encrypted             = false
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name        = "bongaquino-staging-backend"
    Project     = "bongaquino"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}