provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "koneksi" {
  name       = "koneksi-cache-subnet"
  subnet_ids = var.data_private_subnet_ids
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name        = "koneksi-elasticache-sg"
  description = "Security group for Koneksi ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow access from VPC
  }

  tags = {
    Name = "koneksi-elasticache-sg"
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "koneksi" {
  family = "redis7"
  name   = "koneksi-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

# ElastiCache Replication Group
resource "aws_elasticache_replication_group" "koneksi" {
  replication_group_id       = "koneksi-redis"
  description               = "Koneksi Redis cluster"
  node_type                 = "cache.t3.micro"
  port                      = 6379
  parameter_group_name      = aws_elasticache_parameter_group.koneksi.name
  subnet_group_name         = aws_elasticache_subnet_group.koneksi.name
  security_group_ids        = [aws_security_group.elasticache.id]
  automatic_failover_enabled = true
  num_cache_clusters        = 2

  tags = {
    Name = "koneksi-redis"
  }
} 