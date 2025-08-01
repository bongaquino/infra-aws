variable "environment" {
  description = "Environment name"
  type        = string
  default     = "uat"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "koneksi"
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
    Environment = "uat"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
} 