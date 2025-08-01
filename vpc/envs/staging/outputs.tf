output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = [for subnet in aws_subnet.database : subnet.id]
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = [for rt in aws_route_table.private : rt.id]
}

output "data_private_route_table_ids" {
  description = "List of IDs of data private route tables"
  value       = [for rt in aws_route_table.data_private : rt.id]
}

output "nat_gateway_ids" {
  description = "List of IDs of NAT Gateways"
  value       = [for nat in aws_nat_gateway.main : nat.id]
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = [for eip in aws_eip.nat : eip.public_ip]
}

output "alb_security_group_id" {
  description = "ID of the ALB security group (using existing public SG)"  
  value       = aws_security_group.public.id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private.id
}

output "public_security_group_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public.id
}

output "data_private_security_group_id" {
  description = "ID of the data-private security group"
  value       = aws_security_group.data_private.id
}

# =============================================================================
# VPC Endpoints Outputs
# =============================================================================
output "vpc_endpoint_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = var.create_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_ssm_id" {
  description = "ID of the SSM VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.ssm[0].id : null
}

output "vpc_endpoint_ssmmessages_id" {
  description = "ID of the SSM Messages VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.ssmmessages[0].id : null
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
} 