provider "aws" {
  region = "ap-southeast-1"
}

module "ec2" {
  source = "../../modules/instance"

  project     = "koneksi"
  environment = "staging"
  vpc_id      = "vpc-0c20317be26528962"  # VPC ID from state file
  subnet_id   = "subnet-07fd670efb8a816db"  # Public subnet
  ami_id      = "ami-0df7a207adb9748c7"  # Ubuntu 24.04 LTS
  instance_type = "t3a.medium"

  tags = {
    Project     = "koneksi"
    Environment = "staging"
    ManagedBy   = "terraform"
    Component   = "ec2"
  }
}