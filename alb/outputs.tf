output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = var.create_main_alb ? aws_lb.main[0].dns_name : null
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = var.create_main_alb ? aws_lb.main[0].arn : null
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.create_main_alb ? aws_lb.main[0].zone_id : null
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = var.create_main_alb ? aws_lb_target_group.main[0].arn : null
}

output "security_group_id" {
  description = "The ID of the security group used by the ALB"
  value       = var.alb_security_group_id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alarms.arn
}

output "services_alb_dns_name" {
  description = "The DNS name of the services ALB"
  value       = var.create_secondary_alb ? aws_lb.secondary[0].dns_name : null
}

output "services_alb_arn" {
  description = "The ARN of the services ALB"
  value       = var.create_secondary_alb ? aws_lb.secondary[0].arn : null
}

output "services_alb_zone_id" {
  description = "Zone ID of the services load balancer"
  value       = var.create_secondary_alb ? aws_lb.secondary[0].zone_id : null
}

output "services_target_group_arn" {
  description = "The ARN of the services target group"
  value       = var.create_secondary_alb ? data.aws_lb_target_group.existing_services[0].arn : null
}

output "services_listener_arn" {
  description = "The ARN of the services ALB listener"
  value       = var.create_secondary_alb ? aws_lb_listener.secondary_http_8080[0].arn : null
}

output "http_8080_listener_arn" {
  description = "The ARN of the HTTP 8080 listener"
  value       = var.create_secondary_alb ? aws_lb_listener.secondary_http_8080[0].arn : null
}

# CloudWatch Log Groups Outputs
output "main_alb_access_log_group" {
  description = "CloudWatch log group for main ALB access logs"
  value       = var.create_main_alb && var.enable_access_logs ? aws_cloudwatch_log_group.main_alb_access_logs[0].name : null
}

output "main_alb_connection_log_group" {
  description = "CloudWatch log group for main ALB connection logs"
  value       = var.create_main_alb && var.enable_connection_logs ? aws_cloudwatch_log_group.main_alb_connection_logs[0].name : null
}

output "services_alb_access_log_group" {
  description = "CloudWatch log group for services ALB access logs"
  value       = var.create_secondary_alb && var.enable_access_logs ? aws_cloudwatch_log_group.services_alb_access_logs[0].name : null
}

output "services_alb_connection_log_group" {
  description = "CloudWatch log group for services ALB connection logs"
  value       = var.create_secondary_alb && var.enable_connection_logs ? aws_cloudwatch_log_group.services_alb_connection_logs[0].name : null
}

output "lambda_logs_processor_arn" {
  description = "The ARN of the Lambda function that processes ALB logs"
  value       = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) ? aws_lambda_function.alb_logs_processor[0].arn : null
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function that processes ALB logs"
  value       = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) ? aws_lambda_function.alb_logs_processor[0].arn : null
}

output "lambda_function_name" {
  description = "The name of the Lambda function that processes ALB logs"
  value       = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) ? aws_lambda_function.alb_logs_processor[0].function_name : null
} 