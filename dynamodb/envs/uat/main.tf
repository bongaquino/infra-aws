# =============================================================================
# DynamoDB Table for UAT Environment
# =============================================================================

module "dynamodb" {
  source = "../../"

  # Basic Configuration
  project     = var.project
  environment = var.environment
  table_name  = "${var.project}-${var.environment}-users"

  # Table Schema
  hash_key  = var.hash_key
  range_key = var.range_key
  
  # Attributes for DynamoDB
  attributes = [
    {
      name = var.hash_key
      type = "S"
    }
  ]

  # Billing Configuration
  billing_mode = var.billing_mode

  # Features (match actual AWS configuration)
  stream_enabled = var.stream_enabled
  point_in_time_recovery_enabled = var.point_in_time_recovery_enabled

  # Global Secondary Indexes
  global_secondary_indexes = var.global_secondary_indexes

  # VPC Configuration (optional)
  vpc_id = var.vpc_id
  data_private_route_table_ids = var.data_private_route_table_ids

  # AWS Configuration
  aws_region = var.aws_region

  # Tags
  tags = var.tags
} 