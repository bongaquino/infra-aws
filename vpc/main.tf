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
  region = "ap-southeast-1"
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
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# =============================================================================
# Subnet Configurations (per AZ)
# =============================================================================
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnet_cidrs = [for i in range(var.az_count) : "10.0.${i + 1}.0/24"]
  private_subnet_cidrs = [for i in range(var.az_count) : "10.0.${i + 10}.0/24"]
  data_private_subnet_cidrs = [for i in range(var.az_count) : "10.0.${i + 20}.0/24"]
}

resource "aws_subnet" "public" {
  for_each          = { for idx, az in local.azs : az => idx }
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnet_cidrs[each.value]
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-public-subnet-${each.value + 1}"
    Type = "public"
    AZ   = each.key
  })
}

resource "aws_subnet" "private" {
  for_each          = { for idx, az in local.azs : az => idx }
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[each.value]
  availability_zone = each.key
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-private-subnet-${each.value + 1}"
    Type = "private"
    AZ   = each.key
  })
}

resource "aws_subnet" "data_private" {
  for_each          = { for idx, az in local.azs : az => idx }
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.data_private_subnet_cidrs[each.value]
  availability_zone = each.key
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-data-private-subnet-${each.value + 1}"
    Type = "data-private"
    AZ   = each.key
  })
}

# =============================================================================
# NAT Gateway per AZ
# =============================================================================
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-nat-eip-${each.value.tags["AZ"]}"
  })
}

resource "aws_nat_gateway" "main" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-nat-${each.value.tags["AZ"]}"
  })
  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# Route Tables
# =============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.main
  vpc_id   = aws_vpc.main.id
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-private-rt-${each.key}"
  })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "private_nat_access" {
  for_each               = aws_nat_gateway.main
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value.id
}

resource "aws_route_table_association" "public" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each      = aws_subnet.private
  subnet_id     = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "data_private" {
  for_each      = aws_subnet.data_private
  subnet_id     = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# =============================================================================
# Security Groups (unchanged for now, will update for ALB/ASG next)
# =============================================================================
resource "aws_security_group" "public" {
  name        = "${local.name_prefix}-public-sg"
  description = "Security group for public subnet"
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
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-public-sg"
  })
}

resource "aws_security_group" "private" {
  name        = "${local.name_prefix}-private-sg"
  description = "Security group for private subnet"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-private-sg"
  })
}

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from anywhere"
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

  tags = merge(local.standard_tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })
} 