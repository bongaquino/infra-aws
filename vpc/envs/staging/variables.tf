variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "bongaquino"
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
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "ID of an existing VPC to import"
  type        = string
  default     = null
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
  }))
  default = {}
}

variable "database_subnets" {
  description = "Map of database subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
  }))
  default = {}
}

variable "nat_gateways" {
  description = "Map of NAT Gateway configurations"
  type = map(object({
    id = string
  }))
  default = {}
}

variable "route_tables" {
  description = "Map of route table configurations"
  type = object({
    public = string
    private = map(string)
    data_private = map(string)
  })
  default = {
    public = ""
    private = {}
    data_private = {}
  }
}

variable "internet_gateway_id" {
  description = "ID of existing Internet Gateway"
  type        = string
  default     = null
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
  default     = null
}

variable "create_vpc" {
  description = "Whether to create a VPC"
  type        = bool
  default     = true
}

variable "create_igw" {
  description = "Whether to create an Internet Gateway for the VPC"
  type        = bool
  default     = true
}

variable "create_nat_gateways" {
  description = "Whether to create NAT Gateways for the VPC"
  type        = bool
  default     = true
}

variable "create_alb_sg" {
  description = "Whether to create ALB security group"
  type        = bool
  default     = false
}

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 