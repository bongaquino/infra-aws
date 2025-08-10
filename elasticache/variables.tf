variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "elasticache_subnet_ids" {
  description = "List of ElastiCache subnet IDs"
  type        = list(string)
}

variable "private_sg_id" {
  description = "ID of the private security group"
  type        = string
}

variable "node_type" {
  description = "The compute and memory capacity of the nodes"
  type        = string
  default     = "cache.t3.micro"
}

variable "number_cache_clusters" {
  description = "Number of cache clusters (replicas) per replication group"
  type        = number
  default     = 2
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
  default     = true
}

variable "parameter_group_parameters" {
  description = "Map of parameters for the parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    }
  ]
}

variable "kms_key_id" {
  description = "The ARN of the key that you wish to use if encrypting at rest"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Specifies the weekly time range for when maintenance on the cache cluster is performed"
  type        = string
  default     = "sun:05:00-sun:09:00"
}

variable "snapshot_window" {
  description = "Daily time range during which ElastiCache will take a snapshot of the cache cluster"
  type        = string
  default     = "03:00-05:00"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "bongaquino"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "staging"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "port" {
  description = "The port number on which each of the nodes accepts connections."
  type        = number
  default     = 6379
}

variable "parameter_group_name" {
  description = "The name of the parameter group to associate with this replication group."
  type        = string
  default     = "default.redis7"
}

variable "vpc_security_group_id" {
  description = "The ID of the security group from the VPC module to use for ElastiCache"
  type        = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 