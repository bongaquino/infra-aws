output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [for s in aws_subnet.private : s.id]
}

output "data_private_subnet_ids" {
  description = "IDs of the data private subnets."
  value       = [for s in aws_subnet.data_private : s.id]
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = [for n in aws_nat_gateway.main : n.id]
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
  description = "ID of the EC2 security group."
  value       = aws_security_group.ec2.id
} 