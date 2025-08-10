module "vpc" {
  source = "../../../vpc"

  name_prefix = "bongaquino-uat"
  environment = "uat"
  project     = "bongaquino"

  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  
  vpc_cidr = "10.0.0.0/16"
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  database_subnets     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  elasticache_subnets  = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
}

module "elasticache" {
  source = "../../"

  name_prefix = "bongaquino-uat"
  environment = "uat"
  project     = "bongaquino"

  vpc_id                = module.vpc.vpc_id
  vpc_security_group_id = module.vpc.private_sg_id
  private_sg_id         = module.vpc.private_sg_id
  elasticache_subnet_ids = [
    "subnet-0819e628f42bebead",
    "subnet-027268cb40c020053",
    "subnet-03548437404bc9327",
    "subnet-0df92ff6d3f053d8d",
    "subnet-0d412d35804fdb8f3",
    "subnet-07d1a49f5e63553f2"
  ]

  node_type                  = "cache.t3.small"
  number_cache_clusters      = 2
  automatic_failover_enabled = true
  port                       = 6379

  parameter_group_name = "default.redis7"
  parameter_group_parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    }
  ]

  maintenance_window = "sun:05:00-sun:09:00"
  snapshot_window    = "03:00-05:00"

  tags = {
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
} 