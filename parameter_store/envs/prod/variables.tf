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

variable "parameters" {
  description = "Map of parameter names to values for SSM Parameter Store"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of secret names to values for Secrets Manager"
  type        = map(string)
  default     = {}
}

variable "parameter_validation_rules" {
  description = "Map of parameter names to validation rules"
  type        = map(any)
  default     = {}
} 