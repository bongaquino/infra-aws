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

# Import existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# =============================================================================
# Locals
# =============================================================================
locals {
  name_prefix = "${var.project}-${var.environment}"
  azs         = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  vpc_id      = var.vpc_id  # Use the provided VPC ID directly
  
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# VPC - MANAGE EXISTING (Import only, don't recreate)
# =============================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Internet Gateway - MANAGE EXISTING
# =============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Subnets - MANAGE EXISTING
# =============================================================================
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = local.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-public-${substr(each.key, -1, 1)}"
      Type = "public"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-private-${substr(each.key, -1, 1)}"
      Type = "private"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "database" {
  for_each = var.database_subnets

  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-data-private-${substr(each.key, -1, 1)}"
      Type = "database"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Elastic IPs for NAT Gateways - MANAGE EXISTING
# =============================================================================
resource "aws_eip" "nat" {
  for_each = var.nat_gateways

  domain = "vpc"

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-nat-eip-${substr(each.key, -1, 1)}"
    }
  )

  depends_on = [aws_internet_gateway.main]
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# NAT Gateways - MANAGE EXISTING
# =============================================================================
resource "aws_nat_gateway" "main" {
  for_each = var.nat_gateways

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-nat-${substr(each.key, -1, 1)}"
    }
  )

  depends_on = [aws_internet_gateway.main]
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Route Tables - MANAGE EXISTING
# =============================================================================
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "private" {
  for_each = var.route_tables.private

  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main["ap-southeast-1a"].id  # Use the single NAT gateway
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-private-rt-${substr(each.key, -1, 1)}"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "data_private" {
  for_each = var.route_tables.data_private

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-data-private-rt-${substr(each.key, -1, 1)}"
    }
  )
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Route Table Associations - MANAGE EXISTING
# =============================================================================
resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table_association" "data_private" {
  for_each = var.database_subnets

  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.data_private[each.key].id
  
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Security Groups - MANAGE EXISTING
# =============================================================================
# Private Security Group - staging has bongaquino-staging-private-sg
resource "aws_security_group" "private" {
  name        = "${local.name_prefix}-private-sg"
  description = "Security group for private instances"
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
      Name = "${local.name_prefix}-private-sg"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Public Security Group - staging has bongaquino-staging-public-sg (acts as ALB SG)
resource "aws_security_group" "public" {
  name        = "${local.name_prefix}-public-sg"
  description = "Security group for public subnet"
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
      Name = "${local.name_prefix}-public-sg"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Database/Data Private Security Group  
resource "aws_security_group" "data_private" {
  name        = "${local.name_prefix}-data-private-sg"
  description = "Security group for database subnets"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private.id]
    description     = "MySQL from private SG"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.private.id]
    description     = "PostgreSQL from private SG"
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
      Name = "${local.name_prefix}-data-private-sg"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# VPC Endpoints - CREATE NEW
# =============================================================================
# VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
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
      Name = "${local.name_prefix}-vpc-endpoints-sg"
    }
  )
}

# S3 VPC Endpoint (Gateway)
resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-s3-endpoint"
    }
  )
}

# SSM VPC Endpoint
resource "aws_vpc_endpoint" "ssm" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-ssm-endpoint"
    }
  )
}

# SSM Messages VPC Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-ssmmessages-endpoint"
    }
  )
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-ecr-api-endpoint"
    }
  )
}

# ECR Docker VPC Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-ecr-dkr-endpoint"
    }
  )
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-logs-endpoint"
    }
  )
} 