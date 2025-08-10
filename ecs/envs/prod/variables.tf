variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "bongaquino"
}

variable "container_image" {
  description = "Docker image to use for the container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "service_desired_count" {
  description = "Number of instances of the task to run"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "cpu_utilization_target" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 50
}

variable "memory_utilization_target" {
  description = "Target memory utilization percentage"
  type        = number
  default     = 70
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scaling in"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scaling out"
  type        = number
  default     = 300
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(map(string))
  default     = []
}

variable "container_secrets" {
  description = "Secrets for the container"
  type        = list(map(string))
  default     = []
}

variable "target_group_arn" {
  description = "ARN of the target group for the ALB"
  type        = string
} 