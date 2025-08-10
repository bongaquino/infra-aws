variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "ec2_instance_ip" {
  description = "EC2 instance IP address for deployment"
  type        = string
  default     = "52.77.36.120"
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "bongaquino-tech/bongaquino-backend"
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "staging"
}

variable "ssh_user" {
  description = "SSH user for EC2 instance"
  type        = string
  default     = "ubuntu"
}

variable "ssh_key_parameter_name" {
  description = "AWS Systems Manager Parameter Store name for SSH private key"
  type        = string
  default     = "/bongaquino/staging/ssh-key"
} 