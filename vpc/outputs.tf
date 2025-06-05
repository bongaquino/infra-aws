# =============================================================================
# VPC Outputs
# =============================================================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# =============================================================================
# Subnet Outputs
# =============================================================================
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "elasticache_subnet_ids" {
  description = "List of elasticache subnet IDs"
  value       = aws_subnet.elasticache[*].id
}

# =============================================================================
# Route Table Outputs
# =============================================================================
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of database route table IDs"
  value       = aws_route_table.database[*].id
}

output "elasticache_route_table_ids" {
  description = "List of elasticache route table IDs"
  value       = aws_route_table.elasticache[*].id
}

# =============================================================================
# NAT Gateway Outputs
# =============================================================================
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

# =============================================================================
# VPC Endpoint Outputs
# =============================================================================
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "data_private_subnet_ids" {
  description = "IDs of the data private subnets."
  value       = [for s in aws_subnet.data_private : s.id]
}

output "public_sg_id" {
  description = "ID of the public security group."
  value       = aws_security_group.public.id
}

output "private_sg_id" {
  description = "ID of the private security group."
  value       = aws_security_group.private.id
}

output "ec2_sg_id" {
  value       = aws_security_group.public.id
  description = "The ID of the public security group"
} 