variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "versioning_enabled" {
  description = "Whether to enable versioning"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type = list(object({
    id     = string
    status = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration = optional(object({
      days = number
    }))
  }))
  default = []
}

variable "cors_rules" {
  description = "List of CORS rules"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

variable "bucket_policy" {
  description = "JSON formatted bucket policy"
  type        = string
  default     = null
}

variable "bucket_size_threshold" {
  description = "Threshold for bucket size alarm in bytes"
  type        = number
  default     = 1073741824  # 1 GB
}

variable "number_of_objects_threshold" {
  description = "Threshold for number of objects alarm"
  type        = number
  default     = 1000
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

variable "bucket_name" {
  description = "The name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 