variable "environment" {
  description = "Environment name"
  type        = string
  default     = ""
}

variable "parameters" {
  description = "Map of parameter names to values"
  type        = map(string)
  default     = {}
}

variable "secure_parameters" {
  description = "Map of secure parameter names to values"
  type        = map(string)
  default     = {}
}

locals {
  # Use workspace name as environment if not explicitly set
  environment = var.environment != "" ? var.environment : terraform.workspace
  
  # Common tags
  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Service     = "parameter-store"
  }
} 