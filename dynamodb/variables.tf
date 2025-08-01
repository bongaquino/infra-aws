variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Deployment environment (e.g., staging, uat, prod)"
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions"
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  description = "Describe a GSI for the table"
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

variable "local_secondary_indexes" {
  description = "Describe an LSI on the table"
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "deletion_protection_enabled" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "point_in_time_recovery_enabled" {
  description = "Whether to enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption"
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Whether to enable TTL"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "The name of the table attribute to store the TTL timestamp in"
  type        = string
  default     = "ttl"
}

variable "max_read_capacity" {
  description = "Maximum read capacity units"
  type        = number
  default     = 100
}

variable "min_read_capacity" {
  description = "Minimum read capacity units"
  type        = number
  default     = 5
}

variable "max_write_capacity" {
  description = "Maximum write capacity units"
  type        = number
  default     = 100
}

variable "min_write_capacity" {
  description = "Minimum write capacity units"
  type        = number
  default     = 5
}

variable "target_read_capacity_utilization" {
  description = "Target read capacity utilization percentage"
  type        = number
  default     = 70
}

variable "target_write_capacity_utilization" {
  description = "Target write capacity utilization percentage"
  type        = number
  default     = 70
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default     = null
}

variable "data_private_route_table_ids" {
  description = "List of data private route table IDs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "stream_enabled" {
  description = "Enable DynamoDB streams"
  type        = bool
  default     = false
}

 