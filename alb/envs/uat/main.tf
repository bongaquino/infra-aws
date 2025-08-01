# ALB Configuration for UAT
# Using existing security group: sg-019d4659c99b8f22a
# Using existing VPC: vpc-0b98dadc3584aaa34

# Main ALB for UAT
module "main_alb" {
  source = "../../"

  region                = var.region
  environment           = var.environment
  project               = var.project
  vpc_id                = "vpc-0b98dadc3584aaa34"
  public_subnet_ids     = ["subnet-07d1a49f5e63553f2", "subnet-0819e628f42bebead"]
  alb_security_group_id = "sg-019d4659c99b8f22a"  # Use existing security group
  certificate_arn       = var.certificate_arn
  target_port           = var.target_port
  healthcheck_path      = "/check-health"  # Use application health check endpoint
  create_main_alb       = true
  create_secondary_alb  = false
  alb_name             = "koneksi-uat-alb"
  idle_timeout         = 1800  # Increased to 30 minutes for large file operations
  
  # Optimized Health Check Settings
  health_check_interval = var.health_check_interval
  health_check_timeout  = var.health_check_timeout
  healthy_threshold     = var.healthy_threshold
  unhealthy_threshold   = var.unhealthy_threshold
  
  enable_rate_limiting  = false  # Disable rate limiting
  enable_deletion_protection = true  # Enable deletion protection
  enable_access_logs    = true  # Enable access logs
  access_logs_bucket    = "koneksi-uat-alb-logs"  # S3 bucket for access logs
  access_logs_prefix    = "main-alb"  # Prefix for access logs
  enable_connection_logs = true  # Enable connection logs
  connection_logs_bucket = "koneksi-uat-alb-logs"  # S3 bucket for connection logs
  connection_logs_prefix = "main-alb-connections"  # Prefix for connection logs
  enable_s3_notifications = false  # Disable S3 notifications (handled separately)
}

# Services ALB for UAT
module "services_alb" {
  source = "../../"

  region                = var.region
  environment           = var.environment
  project               = var.project
  vpc_id                = "vpc-0b98dadc3584aaa34"
  public_subnet_ids     = ["subnet-07d1a49f5e63553f2", "subnet-0819e628f42bebead"]
  alb_security_group_id = "sg-019d4659c99b8f22a"  # Use existing security group
  certificate_arn       = var.certificate_arn
  target_port           = 8080
  healthcheck_path      = "/"  # Use root path for services ALB
  create_main_alb       = false
  create_secondary_alb  = true
  secondary_alb_name    = "koneksi-uat-alb-services"
  idle_timeout         = 1800  # Increased to 30 minutes for large file operations
  enable_rate_limiting  = false  # Disable rate limiting
  enable_deletion_protection = true  # Enable deletion protection
  enable_access_logs    = true  # Enable access logs
  access_logs_bucket    = "koneksi-uat-alb-logs"  # S3 bucket for access logs
  access_logs_prefix    = "services-alb"  # Prefix for access logs
  enable_connection_logs = true  # Enable connection logs
  connection_logs_bucket = "koneksi-uat-alb-logs"  # S3 bucket for connection logs
  connection_logs_prefix = "services-alb-connections"  # Prefix for connection logs
  enable_s3_notifications = false  # Disable S3 notifications (handled separately)
}

# CloudWatch Logs with Anomaly Detection
module "cloudwatch_logs" {
  source = "../../../cloudwatch_logs"

  environment = var.environment
  project     = var.project
  
  # ALB log groups that will be created
  log_groups = [
    "/aws/applicationloadbalancer/koneksi-uat-alb",
    "/aws/applicationloadbalancer/koneksi-uat-alb-services"
  ]
  
  retention_in_days = 30
  
  # Enable anomaly detection and insights queries
  enable_anomaly_detection = true
  enable_insights_queries  = true
  
  # Optional: Add SNS topic ARNs for alarm notifications
  alarm_actions = []
} 