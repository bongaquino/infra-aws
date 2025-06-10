output "primary_endpoint_address" {
  description = "The address of the endpoint for the primary node in the replication group."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "The address of the endpoint for the reader node in the replication group."
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
} 