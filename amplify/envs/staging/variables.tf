variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "koneksi"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "koneksi-staging"
}

variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
  default     = "koneksi-web-staging"
}

variable "repository" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/koneksi-tech/koneksi-web"
}

variable "branch_name" {
  description = "Git branch to deploy"
  type        = string
  default     = "staging"
}

variable "branch_stage" {
  description = "Amplify branch stage"
  type        = string
  default     = "PRODUCTION"
}

variable "vite_environment" {
  description = "Vite environment variable value"
  type        = string
  default     = "staging"
}

variable "domain_name" {
  description = "Custom domain name (optional)"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token for Amplify"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
} 