variable "environment" {
  description = "Deployment environment (e.g., staging, uat, prod)"
  type        = string
}

variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "koneksi"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
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
  description = "ID of an existing VPC to use. If null, a new VPC will be created"
  type        = string
  default     = null
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
    az         = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
    az         = string
  }))
}

variable "database_subnets" {
  description = "Map of database subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
    az         = string
  }))
}

variable "elasticache_subnets" {
  description = "Map of ElastiCache subnet configurations"
  type = map(object({
    id         = string
    cidr_block = string
    az         = string
  }))
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
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

variable "create_route_tables" {
  description = "Whether to create route tables for the VPC"
  type        = bool
  default     = true
}

variable "create_dhcp_options" {
  description = "Whether to create DHCP options for the VPC"
  type        = bool
  default     = true
}

variable "create_security_groups" {
  description = "Whether to create security groups for the VPC"
  type        = bool
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = true
}

variable "internet_gateway_id" {
  description = "ID of an existing Internet Gateway to use. If null, a new one will be created"
  type        = string
  default     = null
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
    public = object({
      id = string
    })
    private = map(object({
      id = string
    }))
    data_private = map(object({
      id = string
    }))
  })
  default = {
    public = {
      id = null
    }
    private = {}
    data_private = {}
  }
}

variable "dhcp_options_id" {
  description = "ID of existing DHCP options set"
  type        = string
  default     = null
}

variable "security_groups" {
  description = "Map of security group configurations"
  type = object({
    public = optional(object({
      id = string
    }))
    private = object({
      name        = string
      description = string
      ingress = list(object({
        from_port       = number
        to_port         = number
        protocol        = string
        security_groups = list(string)
        description     = string
      }))
    })
  })
  default = {
    private = {
      name        = "private-sg"
      description = "Security group for private subnets"
      ingress = []
    }
  }
}

variable "vpc_endpoints" {
  description = "Map of VPC endpoint configurations"
  type = map(object({
    service = string
    type    = string
  }))
  default = {}
}