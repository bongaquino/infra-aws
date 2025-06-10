variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "service_principal" {
  description = "The service principal to allow assuming the role"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "policy_document" {
  description = "The IAM policy document in JSON format"
  type        = string
}

variable "create_instance_profile" {
  description = "Whether to create an IAM instance profile"
  type        = bool
  default     = false
}

variable "create_user" {
  description = "Whether to create an IAM user"
  type        = bool
  default     = false
}

variable "create_access_key" {
  description = "Whether to create an access key for the IAM user"
  type        = bool
  default     = false
}

variable "create_group" {
  description = "Whether to create an IAM group"
  type        = bool
  default     = false
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "staging"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "users" {
  description = "Map of users to create with their configurations"
  type = map(object({
    username   = string
    department = string
    team       = string
    email      = string
    role       = string
  }))
  default = {}
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 