variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "bongaquino"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
}

variable "healthcheck_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/"
}

variable "lb_healthcheck_path" {
  description = "Path for load balancer health check"
  type        = string
  default     = "/"
}

variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 3000
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the security group for the ALB in UAT"
  type        = string
} 

variable "healthy_threshold" {
  description = "Number of consecutive health check successes before marking target as healthy"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures before marking target as unhealthy"
  type        = number
  default     = 5
} 