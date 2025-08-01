variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Deployment environment (e.g., staging, uat, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "public_subnets" {
  description = "Map of public subnet CIDR blocks"
  type = map(object({
    cidr_block = string
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnet CIDR blocks"
  type = map(object({
    cidr_block = string
  }))
  default = {}
}

variable "database_subnets" {
  description = "Map of database subnet CIDR blocks"
  type = map(object({
    cidr_block = string
  }))
  default = {}
}

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 