provider "aws" {
  region = "ap-southeast-1"
}

# UAT Bastion Instance - matches AWS reality
resource "aws_instance" "uat_bastion" {
  ami           = "ami-02c7683e4ca3ebf58"  # Real AMI from AWS
  instance_type = "t3a.small"             # Real instance type from AWS
  key_name      = "bongaquino-uat-key"       # Real key from AWS
  subnet_id     = "subnet-0819e628f42bebead"  # Public subnet
  vpc_security_group_ids = ["sg-019d4659c99b8f22a"]  # Real security group from AWS
  
  # Match real configuration
  monitoring                 = false
  ebs_optimized             = true
  source_dest_check         = true
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8  # Will check real size and adjust
    delete_on_termination = true
    encrypted             = false
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name        = "bongaquino-uat-bastion"
    Project     = "bongaquino"
    Environment = "uat"
    ManagedBy   = "terraform"
  }
}

# UAT Redis Instance - match real AWS configuration
resource "aws_instance" "uat_redis" {
  ami           = "ami-02c7683e4ca3ebf58"  # Assuming same AMI
  instance_type = "c5.large"              # From AWS reality
  key_name      = "bongaquino-uat-key"       
  subnet_id     = "subnet-0b641380f01a517ab"  # Real subnet from plan output
  vpc_security_group_ids = ["sg-08ff2826707f3969c"]  # Real security group from plan
  
  monitoring                 = true   # Real setting from plan
  ebs_optimized             = true
  source_dest_check         = true
  associate_public_ip_address = false  # Private instance
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 25  # Real volume size from plan
    delete_on_termination = true
    encrypted             = false
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags = "disabled"  # Real setting
  }

  tags = {
    Name        = "bongaquino-uat-redis"
    Project     = "bongaquino"
    Environment = "uat"
    ManagedBy   = "terraform"
  }
}

# UAT MongoDB Instance - match real AWS configuration
resource "aws_instance" "uat_mongodb" {
  ami           = "ami-02c7683e4ca3ebf58"  # Assuming same AMI
  instance_type = "c5.large"              # From AWS reality
  key_name      = "bongaquino-uat-key"       
  subnet_id     = "subnet-0b641380f01a517ab"  # Real subnet from plan output
  vpc_security_group_ids = ["sg-08ff2826707f3969c"]  # Real security group from plan
  
  monitoring                 = true   # Real setting from plan
  ebs_optimized             = true
  source_dest_check         = true
  associate_public_ip_address = false  # Private instance
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 200  # Real volume size from plan
    delete_on_termination = true
    encrypted             = false
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags = "disabled"  # Real setting
  }

  tags = {
    Name        = "bongaquino-uat-mongodb"
    Project     = "bongaquino"
    Environment = "uat"
    ManagedBy   = "terraform"
  }
}

# UAT Tyk Instance - match real AWS configuration
resource "aws_instance" "uat_tyk" {
  ami           = "ami-02c7683e4ca3ebf58"  # Assuming same AMI
  instance_type = "c5.xlarge"             # From AWS reality
  key_name      = "bongaquino-uat-key"       
  subnet_id     = "subnet-036b8051cba048269"  # Real subnet from plan output
  vpc_security_group_ids = ["sg-05eedf18d93530de8"]  # Real security group from plan
  
  monitoring                 = true   # Real setting from plan
  ebs_optimized             = true
  source_dest_check         = true
  associate_public_ip_address = false  # Private instance
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 25  # Real volume size from plan
    delete_on_termination = true
    encrypted             = false
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags = "disabled"  # Real setting
  }

  tags = {
    Name        = "bongaquino-uat-tyk"
    Project     = "bongaquino"
    Environment = "uat"
    ManagedBy   = "terraform"
  }
}

# UAT TSDB Instance - match real AWS configuration
resource "aws_instance" "uat_tsdb" {
  ami           = "ami-02c7683e4ca3ebf58"  # Assuming same AMI
  instance_type = "t3a.medium"            # From AWS reality
  key_name      = "bongaquino-uat-key"       
  subnet_id     = "subnet-0b641380f01a517ab"  # Real subnet from plan output
  vpc_security_group_ids = ["sg-08ff2826707f3969c"]  # Real security group from plan
  
  monitoring                 = true   # Real setting from plan
  ebs_optimized             = true
  source_dest_check         = true
  associate_public_ip_address = false  # Private instance
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 25  # Real volume size from plan
    delete_on_termination = true
    encrypted             = false
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags = "disabled"  # Real setting
  }

  tags = {
    Name        = "bongaquino-uat-tsdb"
    Project     = "bongaquino"
    Environment = "uat"
    ManagedBy   = "terraform"
  }
} 