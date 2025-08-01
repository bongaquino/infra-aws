variable "environment" {
  description = "Environment name (uat, staging, prod)"
  type        = string
}

variable "api_response_time_threshold" {
  description = "API response time threshold in milliseconds"
  type        = number
  default     = 1000
}

variable "active_users_threshold" {
  description = "Active users spike threshold"
  type        = number
  default     = 1000
}

variable "min_daily_active_users" {
  description = "Minimum expected daily active users"
  type        = number
  default     = 10
}

variable "max_daily_storage_growth_gb" {
  description = "Maximum expected daily storage growth in GB"
  type        = number
  default     = 50
} 