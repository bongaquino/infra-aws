# ALB Configuration for Staging
# Using existing security group: sg-066e2c5f4bfdab814 (koneksi-staging-public-sg)
# Using existing VPC: vpc-0c20317be26528962

# Main ALB for Staging
module "main_alb" {
  source = "../../"

  region                = var.region
  environment           = var.environment
  project               = var.project
  vpc_id                = "vpc-0c20317be26528962"
  public_subnet_ids     = ["subnet-07fd670efb8a816db", "subnet-0448319959f42f750"]
  alb_security_group_id = "sg-066e2c5f4bfdab814"  # Use existing security group
  certificate_arn       = var.certificate_arn
  target_port           = var.target_port
  healthcheck_path      = "/check-health"  # Use application health check endpoint
  create_main_alb       = true
  create_secondary_alb  = false
  alb_name             = "koneksi-staging-alb"
  idle_timeout         = 1800  # Increased to 30 minutes for large file operations
  
  # Optimized Health Check Settings
  health_check_interval = var.health_check_interval
  health_check_timeout  = var.health_check_timeout
  healthy_threshold     = var.healthy_threshold
  unhealthy_threshold   = var.unhealthy_threshold
  
  enable_rate_limiting  = false  # Disable rate limiting
  enable_deletion_protection = true  # Enable deletion protection
  enable_access_logs    = true  # Enable access logs
  access_logs_bucket    = "koneksi-staging-alb-logs"  # S3 bucket for access logs
  access_logs_prefix    = "main-alb"  # Prefix for access logs
  enable_connection_logs = true  # Enable connection logs
  connection_logs_bucket = "koneksi-staging-alb-logs"  # S3 bucket for connection logs
  connection_logs_prefix = "main-alb-connections"  # Prefix for connection logs
  enable_s3_notifications = false  # Disable S3 notifications (handled separately)
} 