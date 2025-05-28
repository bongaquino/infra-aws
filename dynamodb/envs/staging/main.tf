module "dynamodb" {
  source = "../.."

  project     = var.project
  environment = var.environment
  table_name  = var.table_name

  billing_mode               = var.billing_mode
  hash_key                   = var.hash_key
  hash_key_type             = var.hash_key_type
  enable_point_in_time_recovery = var.enable_point_in_time_recovery
  enable_server_side_encryption = var.enable_server_side_encryption
} 