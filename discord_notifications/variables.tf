# =============================================================================
# Required Variables
# =============================================================================
variable "discord_webhook_url" {
  description = "Discord webhook URL for sending notifications"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (e.g., staging, uat, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

# =============================================================================
# Optional Variables
# =============================================================================
variable "discord_username" {
  description = "Default username for Discord webhook messages"
  type        = string
  default     = "AWS Notifications"
}

variable "discord_avatar_url" {
  description = "Avatar URL for Discord webhook messages"
  type        = string
  default     = "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original.svg"
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "koneksi"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "store_webhook_in_parameter_store" {
  description = "Whether to store the Discord webhook URL in AWS Systems Manager Parameter Store"
  type        = bool
  default     = false
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
  default     = "3447003" # Blue color (standardized)
}

variable "enable_mentions" {
  description = "Enable @here or @everyone mentions for critical alerts"
  type        = bool
  default     = false
}

variable "critical_message_color" {
  description = "Color for critical/error messages (hex color code)"
  type        = string
  default     = "15158332" # Red color (correct)
}

variable "warning_message_color" {
  description = "Color for warning messages (hex color code)"
  type        = string
  default     = "16776960" # Orange color (correct)
}

variable "success_message_color" {
  description = "Color for success messages (hex color code)"
  type        = string
  default     = "65280" # Green color (FIXED - was wrong 3066993)
}

# =============================================================================
# Local Values
# =============================================================================
locals {
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "discord-notifications"
    ManagedBy   = "terraform"
  })
  
  # Function name
  lambda_function_name = "${var.name_prefix}-${var.environment}-discord-notifier"
  
  # SNS topic name
  sns_topic_name = "${var.name_prefix}-${var.environment}-discord-notifications"
} 