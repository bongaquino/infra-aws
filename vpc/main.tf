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
# Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# VPC Core Resources
# =============================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-vpc"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-igw"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Subnet Configurations
# =============================================================================
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  public_subnet_cidrs = {
    for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index(local.azs, az) + 1)
  }
  
  private_subnet_cidrs = {
    for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index(local.azs, az) + 10)
  }
  
  data_private_subnet_cidrs = {
    for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index(local.azs, az) + 20)
  }
}

resource "aws_subnet" "public" {
  for_each          = local.public_subnet_cidrs
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-public-subnet-${index(local.azs, each.key) + 1}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "private" {
  for_each          = local.private_subnet_cidrs
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-private-subnet-${index(local.azs, each.key) + 1}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "data_private" {
  for_each          = local.data_private_subnet_cidrs
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-data-private-subnet-${index(local.azs, each.key) + 1}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# NAT Gateway Configuration
# =============================================================================
resource "aws_eip" "nat" {
  for_each = { for i, az in local.azs : az => i }
  domain   = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-eip-${each.value + 1}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_nat_gateway" "main" {
  for_each      = { for i, az in local.azs : az => i }
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-nat-${each.value + 1}"
    }
  )
  
  depends_on = [aws_internet_gateway.main]

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Route Tables
# =============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-public-rt"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "private" {
  for_each = { for i, az in local.azs : az => i }
  vpc_id   = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-private-rt-${each.value + 1}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "data_private" {
  for_each = { for i, az in local.azs : az => i }
  vpc_id   = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-data-private-rt-${each.value + 1}"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Route Table Associations
# =============================================================================
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table_association" "data_private" {
  for_each       = aws_subnet.data_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data_private[each.key].id

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Security Groups
# =============================================================================
resource "aws_security_group" "bastion" {
  name        = "${var.project}-${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 22
    to_port     = 22
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
    var.tags,
    {
      Name = "${var.project}-${var.environment}-bastion-sg"
    }
  )
}

resource "aws_security_group" "private" {
  name        = "${var.project}-${var.environment}-private-sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.bastion.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-private-sg"
    }
  )
} 