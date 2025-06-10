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
  value       = [for s in values(aws_subnet.public) : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for s in values(aws_subnet.private) : s.id]
}

output "data_private_subnet_ids" {
  description = "IDs of the data private subnets."
  value       = [for s in values(aws_subnet.data_private) : s.id]
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
  value       = [for rt in values(aws_route_table.private) : rt.id]
}

output "data_private_route_table_ids" {
  description = "List of data private route table IDs"
  value       = [for rt in values(aws_route_table.data_private) : rt.id]
}

# =============================================================================
# NAT Gateway Outputs
# =============================================================================
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = [for nat in values(aws_nat_gateway.main) : nat.id]
}

output "nat_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = [for eip in values(aws_eip.nat) : eip.public_ip]
}

# =============================================================================
# Security Group Outputs
# =============================================================================
output "bastion_sg_id" {
  description = "ID of the bastion security group."
  value       = aws_security_group.bastion.id
}

output "private_sg_id" {
  description = "ID of the private security group."
  value       = aws_security_group.private.id
}