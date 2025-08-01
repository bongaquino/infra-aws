module "vpc" {
  source = "../../../vpc"

  environment         = var.environment
  project            = var.project
  name_prefix        = "prod"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  vpc_cidr           = "10.2.0.0/16"
  public_subnets     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnets    = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
  database_subnets   = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]
  elasticache_subnets = ["10.2.31.0/24", "10.2.32.0/24", "10.2.33.0/24"]
}

module "ecs" {
  source = "../../../ecs"

  region              = var.region
  environment         = var.environment
  project            = var.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  container_image    = var.container_image
  container_port     = var.container_port
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  service_desired_count = var.service_desired_count
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  cpu_utilization_target = var.cpu_utilization_target
  memory_utilization_target = var.memory_utilization_target
  scale_in_cooldown  = var.scale_in_cooldown
  scale_out_cooldown = var.scale_out_cooldown
  log_retention_days = var.log_retention_days
  container_environment = var.container_environment
  container_secrets  = var.container_secrets
  target_group_arn   = var.target_group_arn
  ecs_security_group_id = module.vpc.ecs_security_group_id
} 