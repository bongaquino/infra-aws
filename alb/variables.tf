variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "target_port" {
  description = "Target port for the ALB target group"
  type        = number
  default     = 8080
}

variable "healthcheck_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/api"
}

variable "create_main_alb" {
  description = "Whether to create the main ALB"
  type        = bool
  default     = true
}

variable "create_secondary_alb" {
  description = "Whether to create the secondary ALB"
  type        = bool
  default     = false
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
  default     = ""
}

variable "secondary_alb_name" {
  description = "Name of the secondary ALB"
  type        = string
  default     = ""
}

variable "idle_timeout" {
  description = "The idle timeout in seconds. The valid range is 1-4000 seconds."
  type        = number
  default     = 60
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds (2-120)"
  type        = number
  default     = 30  # Must be less than interval
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 60  # Must be greater than timeout
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures before marking target as unhealthy"
  type        = number
  default     = 3
}

variable "healthy_threshold" {
  description = "Number of consecutive health check successes before marking target as healthy"
  type        = number
  default     = 2
}

variable "enable_stickiness" {
  description = "Enable session stickiness for load balancer"
  type        = bool
  default     = true
}

variable "stickiness_duration" {
  description = "Session stickiness duration in seconds"
  type        = number
  default     = 86400
}

variable "enable_rate_limiting" {
  description = "Enable rate limiting for file operations"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALBs"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable access logs for ALB"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = ""
}

variable "enable_connection_logs" {
  description = "Enable connection logs for ALB"
  type        = bool
  default     = false
}

variable "connection_logs_bucket" {
  description = "S3 bucket name for ALB connection logs"
  type        = string
  default     = ""
}

variable "connection_logs_prefix" {
  description = "S3 prefix for ALB connection logs"
  type        = string
  default     = ""
}

variable "enable_s3_notifications" {
  description = "Enable S3 bucket notifications for Lambda function (set to false when handling notifications separately)"
  type        = bool
  default     = true
} 