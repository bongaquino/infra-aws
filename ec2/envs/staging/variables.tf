variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "vpc_id" {
  description = "VPC ID where the instances will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instances will be created"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0df7a207adb9748c7"  # Ubuntu 22.04 LTS in ap-southeast-1
}

variable "instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
  default     = "t3a.micro"
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "koneksi"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
} 