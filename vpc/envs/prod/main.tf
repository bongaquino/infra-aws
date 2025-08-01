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
# Locals
# =============================================================================
locals {
  name_prefix = "${var.project}-${var.environment}"
  azs         = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# VPC - CREATE NEW
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
}

# =============================================================================
# Internet Gateway - CREATE NEW
# =============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

# =============================================================================
# Subnets - CREATE NEW
# =============================================================================
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
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
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-private-${substr(each.key, -1, 1)}"
      Type = "private"
    }
  )
}

resource "aws_subnet" "database" {
  for_each = var.database_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-database-${substr(each.key, -1, 1)}"
      Type = "database"
    }
  )
}

# =============================================================================
# Elastic IP for NAT Gateway - COMMENTED OUT FOR COST SAVINGS
# =============================================================================
# resource "aws_eip" "nat" {
#   domain = "vpc"

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.name_prefix}-nat-eip"
#     }
#   )

#   depends_on = [aws_internet_gateway.main]
# }

# =============================================================================
# NAT Gateway - COMMENTED OUT FOR COST SAVINGS
# =============================================================================
# resource "aws_nat_gateway" "main" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public["ap-southeast-1a"].id

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.name_prefix}-nat"
#     }
#   )

#   depends_on = [aws_internet_gateway.main]
# }

# =============================================================================
# Route Tables - CREATE NEW
# =============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

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
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.main.id

  # No internet route - private subnets without NAT gateway
  # route {
  #   cidr_block     = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.main.id
  # }

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-private-rt-${substr(each.key, -1, 1)}"
    }
  )
}

resource "aws_route_table" "database" {
  for_each = var.database_subnets

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-database-rt-${substr(each.key, -1, 1)}"
    }
  )
}

# =============================================================================
# Route Table Associations - CREATE NEW
# =============================================================================
resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "database" {
  for_each = var.database_subnets

  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.database[each.key].id
}

# =============================================================================
# Security Groups - CREATE NEW
# =============================================================================
# Public Security Group (acts as ALB SG)
resource "aws_security_group" "public" {
  name        = "${local.name_prefix}-public-sg"
  description = "Security group for public subnet and ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tyk Gateway"
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
      Name = "${local.name_prefix}-public-sg"
    }
  )
}

# Private Security Group
resource "aws_security_group" "private" {
  name        = "${local.name_prefix}-private-sg"
  description = "Security group for private subnets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
    description     = "SSH access from public SG (ALB)"
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
    description     = "App traffic from public SG (ALB)"
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
    description     = "Tyk Gateway from public SG (ALB)"
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
      Name = "${local.name_prefix}-private-sg"
    }
  )
}

# Database/Data Private Security Group
resource "aws_security_group" "data_private" {
  name        = "${local.name_prefix}-data-private-sg"
  description = "Security group for database subnets"
  vpc_id      = aws_vpc.main.id

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
}

# =============================================================================
# VPC Endpoints - CREATE NEW
# =============================================================================
# VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

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

  vpc_id            = aws_vpc.main.id
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

  vpc_id            = aws_vpc.main.id
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

  vpc_id            = aws_vpc.main.id
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

  vpc_id            = aws_vpc.main.id
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

  vpc_id            = aws_vpc.main.id
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