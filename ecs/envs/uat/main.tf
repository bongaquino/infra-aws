provider "aws" {
  region  = var.region
  profile = "koneksi"
}

data "aws_lb_target_group" "main" {
  name = "koneksi-uat-tg"
}

module "ecs" {
  source = "../../"

  region                  = var.region
  environment             = var.environment
  project                 = var.project
  vpc_id                  = var.vpc_id
  private_subnet_ids      = var.private_subnet_ids
  container_image         = var.container_image
  container_port          = var.container_port
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  service_desired_count   = var.service_desired_count
  max_capacity            = var.max_capacity
  min_capacity            = var.min_capacity
  cpu_utilization_target  = var.cpu_utilization_target
  memory_utilization_target = var.memory_utilization_target
  scale_in_cooldown       = var.scale_in_cooldown
  scale_out_cooldown      = var.scale_out_cooldown
  log_retention_days      = var.log_retention_days
  container_environment   = []
  container_secrets = [
    { name = "APP_NAME", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/APP_NAME" },
    { name = "APP_VERSION", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/APP_VERSION" },
    { name = "IPFS_NODE_URL", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/IPFS_NODE_URL" },
    { name = "JWT_REFRESH_EXPIRATION", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/JWT_REFRESH_EXPIRATION" },
    { name = "JWT_SECRET", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/JWT_SECRET" },
    { name = "POSTMARK_API_KEY", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/POSTMARK_API_KEY" },
    { name = "POSTMARK_FROM", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/POSTMARK_FROM" },
    { name = "REDIS_HOST", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/REDIS_HOST" },
    { name = "REDIS_PORT", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/REDIS_PORT" },
    { name = "REDIS_PREFIX", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/REDIS_PREFIX" },
    { name = "APP_KEY", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/APP_KEY" },
    { name = "IPFS_DOWNLOAD_URL", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/IPFS_DOWNLOAD_URL" },
    { name = "JWT_TOKEN_EXPIRATION", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/JWT_TOKEN_EXPIRATION" },
    { name = "MODE", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/MODE" },
    { name = "MONGO_DATABASE", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/MONGO_DATABASE" },
    { name = "MONGO_HOST", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/MONGO_HOST" },
    { name = "MONGO_PASSWORD", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/MONGO_PASSWORD" },
    { name = "MONGO_PORT", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/MONGO_PORT" },
    { name = "MONGO_USER", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/MONGO_USER" },
    { name = "PORT", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/PORT" },
    { name = "DB_PASSWORD", valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/koneksi/uat/db/password" }
  ]
  ecs_security_group_id   = var.ecs_security_group_id
  alb_security_group_id   = var.alb_security_group_id
  target_group_arn        = data.aws_lb_target_group.main.arn
}

module "parameter_store" {
  source      = "../../../parameter_store"
  environment = var.environment
  parameters = {
    # Non-sensitive parameters (if any)
  }
  secure_parameters = {
    # Secure parameters are already managed externally
    # This module ensures they exist and are properly tagged
  }
}

# Removed problematic cloudwatch_logs module - logs are managed by main ECS module

 