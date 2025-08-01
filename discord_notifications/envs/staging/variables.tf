# =============================================================================
# Required Variables
# =============================================================================
variable "discord_webhook_url" {
  description = "Discord webhook URL for staging notifications"
  type        = string
  sensitive   = true
}

# =============================================================================
# Environment Variables
# =============================================================================
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
  default     = "🟡 Koneksi Staging Bot"
}

variable "discord_avatar_url" {
  description = "Avatar URL for Discord webhook messages"
  type        = string
  default     = "https://example.com/staging-bot-avatar.png"
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
# Message Formatting Variables
# =============================================================================
variable "message_color" {
  description = "Default color for Discord embed messages (hex color code)"
  type        = string
  default     = "3394815" # Light Blue
}

variable "enable_mentions" {
  description = "Enable @here or @everyone mentions for critical alerts"
  type        = bool
  default     = false
}

variable "critical_message_color" {
  description = "Color for critical/error messages (hex color code)"
  type        = string
  default     = "15158332" # Red color
}

variable "warning_message_color" {
  description = "Color for warning messages (hex color code)"
  type        = string
  default     = "16776960" # Orange color
}

variable "success_message_color" {
  description = "Color for success messages (hex color code)"
  type        = string
  default     = "65280" # Green color
}

# =============================================================================
# Tags
# =============================================================================
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "koneksi"
    Owner       = "devops"
    Purpose     = "discord-notifications"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
} 