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