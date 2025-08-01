variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "koneksi"
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs integration"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable log file validation"
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "Include global service events"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Enable multi-region trail"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging for the trail"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for CloudTrail encryption"
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = null
}

variable "s3_lifecycle_days" {
  description = "Number of days to retain logs in S3"
  type        = number
  default     = 90
}

variable "s3_noncurrent_version_days" {
  description = "Number of days to retain non-current versions"
  type        = number
  default     = 30
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "enable_security_monitoring" {
  description = "Enable security monitoring with metric filters and alarms"
  type        = bool
  default     = true
}

variable "enable_anomaly_detection" {
  description = "Enable CloudWatch Anomaly Detection for automatic detection of unusual log patterns"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
} 