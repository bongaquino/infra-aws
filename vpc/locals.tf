# =============================================================================
# Local Variables
# =============================================================================
locals {
  name_prefix = "${var.project}-${var.environment}"
  
  standard_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
} 