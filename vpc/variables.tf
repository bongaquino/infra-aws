variable "environment" {
  description = "Deployment environment (e.g., staging, uat, prod)"
  type        = string
}

variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "koneksi"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "staging"
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  standard_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
} 