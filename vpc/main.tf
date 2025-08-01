# =============================================================================
# Terraform Configuration
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_availability_zones" "available" {}

# =============================================================================
# VPC Creation Logic
# =============================================================================

# CREATE NEW VPC if vpc_id is null
resource "aws_vpc" "new" {
  count = var.vpc_id == null ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# MANAGE EXISTING VPC if vpc_id is provided (for import)
resource "aws_vpc" "existing" {
  count = var.vpc_id != null ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
  
  lifecycle {
    prevent_destroy = true
  }
}

# USE EXISTING VPC if vpc_id is provided (data source for reference)
data "aws_vpc" "existing" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

# =============================================================================
# Internet Gateway - ALWAYS MANAGED
# =============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = local.vpc_id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# =============================================================================
# Locals - CONSOLIDATED
# =============================================================================
locals {
  vpc_id = var.vpc_id != null ? aws_vpc.existing[0].id : aws_vpc.new[0].id
  vpc_cidr_actual = var.vpc_id != null ? aws_vpc.existing[0].cidr_block : aws_vpc.new[0].cidr_block
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# VPC Endpoints
# =============================================================================
resource "aws_vpc_endpoint" "ssm" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in values(var.private_subnets) : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "koneksi-${var.environment}-ssm-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in values(var.private_subnets) : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "koneksi-${var.environment}-ssmmessages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in values(var.private_subnets) : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "koneksi-${var.environment}-ecr-api-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in values(var.private_subnets) : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "koneksi-${var.environment}-ecr-dkr-endpoint"
    }
  )
}

# =============================================================================
# Security Groups
# =============================================================================
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name        = "koneksi-${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.create_security_groups ? [aws_security_group.private[0].id] : []
  }

  tags = merge(
    local.tags,
    {
      Name = "koneksi-${var.environment}-vpc-endpoints-sg"
    }
  )
}

resource "aws_security_group" "private" {
  count = var.create_security_groups ? 1 : 0

  name        = "private-sg"
  description = "Security group for private subnets"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "koneksi-${var.environment}-private-sg"
    }
  )
}

resource "aws_security_group" "alb" {
  count = var.create_security_groups ? 1 : 0
  
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
} 