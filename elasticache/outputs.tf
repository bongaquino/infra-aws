output "primary_endpoint_address" {
  description = "Primary endpoint address of the ElastiCache Redis cluster."
  value       = aws_elasticache_replication_group.koneksi.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address of the ElastiCache Redis cluster."
  value       = aws_elasticache_replication_group.koneksi.reader_endpoint_address
}

output "elasticache_sg_id" {
  description = "Security group ID for ElastiCache."
  value       = aws_security_group.elasticache.id
} 