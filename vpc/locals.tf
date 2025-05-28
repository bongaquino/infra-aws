locals {
  name_prefix = "${var.project}-${var.environment}"
  standard_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
} 