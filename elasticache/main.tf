# =============================================================================
# Terraform Configuration
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# =============================================================================
# ElastiCache Subnet Group
# =============================================================================
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = var.elasticache_subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-subnet-group"
  })
}

# =============================================================================
# ElastiCache Parameter Group
# =============================================================================
resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${var.name_prefix}-redis-params"
  
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-params"
  })
}

# =============================================================================
# ElastiCache Replication Group
# =============================================================================
resource "aws_elasticache_replication_group" "main" {
  description                = "Redis cluster for ${var.name_prefix}"
  replication_group_id       = "${var.name_prefix}-redis"
  node_type                  = var.node_type
  port                        = var.port
  parameter_group_name       = var.parameter_group_name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.vpc_security_group_id]
  automatic_failover_enabled = var.automatic_failover_enabled
  num_cache_clusters         = var.number_cache_clusters
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  kms_key_id = var.kms_key_id
  
  maintenance_window = var.maintenance_window
  snapshot_window    = var.snapshot_window
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-redis"
    }
  )
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.name_prefix}-redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors Redis CPU utilization"
  
  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "${var.name_prefix}-redis-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors Redis memory utilization"
  
  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
  
  tags = var.tags
} 