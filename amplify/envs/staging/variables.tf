variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "bongaquino"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "bongaquino-staging"
}

variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
  default     = "bongaquino-web-staging"
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
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
} 