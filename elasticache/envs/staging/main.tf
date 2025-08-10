module "elasticache" {
  source = "../../"

  name_prefix = "bongaquino"
  environment = "staging"
  project     = "bongaquino"

  vpc_id                = "vpc-0b98dadc3584aaa34"  # UAT VPC ID from previous conversation
  vpc_security_group_id = "sg-05eedf18d93530de8"   # New private security group
  private_sg_id         = "sg-05eedf18d93530de8"   # New private security group
  
  # Using the same subnet IDs as UAT since it's in the same VPC
  elasticache_subnet_ids = [
    "subnet-0819e628f42bebead",
    "subnet-027268cb40c020053",
    "subnet-03548437404bc9327"
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
    Environment = "staging"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
} 