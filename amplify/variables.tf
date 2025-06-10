variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
}

variable "repository" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "branch_name" {
  description = "Name of the branch to deploy"
  type        = string
  default     = "main"
}

variable "domain_name" {
  description = "Domain name for the Amplify app"
  type        = string
}

variable "api_url" {
  description = "API URL for the frontend application"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "staging"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "koneksi"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "basic_auth_username" {
  description = "Username for basic authentication"
  type        = string
  default     = "admin"
}

variable "basic_auth_password" {
  description = "Password for basic authentication"
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 