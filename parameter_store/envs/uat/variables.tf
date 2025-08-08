variable "environment" {
  description = "Environment name"
  type        = string
  default     = "uat"
}

variable "parameters" {
  description = "Map of parameter names to values for SSM Parameter Store"
  type        = map(string)
  default     = {}
}

variable "secure_parameters" {
  description = "Map of secure parameter names to values"
  type        = map(string)
  default     = {}
} 