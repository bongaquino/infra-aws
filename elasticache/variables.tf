variable "vpc_id" {
  description = "The VPC ID to deploy ElastiCache into."
  type        = string
}

variable "data_private_subnet_ids" {
  description = "The subnet IDs for ElastiCache deployment."
  type        = list(string)
} 