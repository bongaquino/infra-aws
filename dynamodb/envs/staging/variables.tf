variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
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
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
}

variable "hash_key" {
  description = "Hash key (partition key) for the DynamoDB table"
  type        = string
}

variable "hash_key_type" {
  description = "Data type of the hash key (S for string, N for number, B for binary)"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for the DynamoDB table"
  type        = bool
}

variable "enable_server_side_encryption" {
  description = "Enable server-side encryption for the DynamoDB table"
  type        = bool
} 