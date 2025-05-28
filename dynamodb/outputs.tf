output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.koneksi_table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.koneksi_table.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.koneksi_table.id
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB table stream"
  value       = aws_dynamodb_table.koneksi_table.stream_arn
} 