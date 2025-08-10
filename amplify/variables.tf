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
<<<<<<< HEAD
  default     = "https://github.com/bongaquino/bongaquino-web"
=======
  default     = "https://github.com/bongaquino/bongaquino-web"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
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

variable "branch_stage" {
  description = "Stage of the branch (PRODUCTION, DEVELOPMENT, etc.)"
  type        = string
  default     = "PRODUCTION"
}

variable "domain_name" {
  description = "Domain name for the Amplify app (optional)"
  type        = string
  default     = ""
}

variable "vite_environment" {
  description = "Vite environment variable value"
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
  default     = "bongaquino"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 