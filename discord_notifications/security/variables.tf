# =============================================================================
# Required Variables
# =============================================================================
variable "discord_webhook_url" {
  description = "Discord webhook URL for security notifications"
  type        = string
  sensitive   = true
}

# =============================================================================
# Environment Variables
# =============================================================================
variable "project" {
  description = "Project name"
  type        = string
  default     = "bongaquino"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# =============================================================================
# Optional Variables
# =============================================================================
variable "discord_username" {
  description = "Username for Discord webhook messages"
  type        = string
  default     = "🛡️ bongaquino Security Bot"
}

variable "discord_avatar_url" {
  description = "Avatar URL for Discord webhook messages"
  type        = string
  default     = "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original.svg"
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
}

variable "store_webhook_in_parameter_store" {
  description = "Whether to store the Discord webhook URL in AWS Systems Manager Parameter Store"
  type        = bool
  default     = true
}

variable "enable_lambda_monitoring" {
  description = "Enable CloudWatch monitoring and alarms for the Lambda function"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when Lambda function fails"
  type        = list(string)
  default     = []
}

# =============================================================================
# Security-Specific Variables
# =============================================================================
variable "enable_critical_mentions" {
  description = "Enable @here mentions for critical security alerts"
  type        = bool
  default     = false
}

variable "security_alert_threshold" {
  description = "Minimum severity level for security alerts (1-10)"
  type        = number
  default     = 4
}

# =============================================================================
# Tags
# =============================================================================
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "account-wide"
    Owner       = "security"
    Purpose     = "security-monitoring"
  }
} 