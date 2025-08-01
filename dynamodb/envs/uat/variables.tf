# =============================================================================
# Required Variables
# =============================================================================
variable "project" {
  description = "Project name"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "uat"
}

variable "hash_key" {
  description = "Hash key for DynamoDB table"
  type        = string
}

variable "range_key" {
  description = "Range key for DynamoDB table"
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# =============================================================================
# Feature Configuration
# =============================================================================
variable "stream_enabled" {
  description = "Enable DynamoDB streams"
  type        = bool
  default     = false
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point in time recovery"
  type        = bool
  default     = false
}

# =============================================================================
# Global Secondary Indexes
# =============================================================================
variable "global_secondary_indexes" {
  description = "Global secondary indexes for the table"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    projection_type    = string
    read_capacity      = number
    write_capacity     = number
  }))
  default = []
}

# =============================================================================
# AWS Configuration
# =============================================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# =============================================================================
# VPC Configuration (Optional)
# =============================================================================
variable "vpc_id" {
  description = "VPC ID for DynamoDB VPC endpoint"
  type        = string
  default     = null
}

variable "data_private_route_table_ids" {
  description = "Private route table IDs for DynamoDB VPC endpoint"
  type        = list(string)
  default     = []
}

# =============================================================================
# Tags
# =============================================================================
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 