# =============================================================================
# SNS Topic Outputs
# =============================================================================
output "sns_topic_arn" {
  description = "ARN of the SNS topic for Discord notifications"
  value       = aws_sns_topic.discord_notifications.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for Discord notifications"
  value       = aws_sns_topic.discord_notifications.name
}

# =============================================================================
# Lambda Function Outputs
# =============================================================================
output "lambda_function_arn" {
  description = "ARN of the Discord notification Lambda function"
  value       = aws_lambda_function.discord_notifier.arn
}

output "lambda_function_name" {
  description = "Name of the Discord notification Lambda function"
  value       = aws_lambda_function.discord_notifier.function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Discord notification Lambda function"
  value       = aws_lambda_function.discord_notifier.invoke_arn
}

# =============================================================================
# IAM Role Outputs
# =============================================================================
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.discord_lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.discord_lambda_role.name
}

# =============================================================================
# CloudWatch Outputs
# =============================================================================
output "log_group_name" {
  description = "Name of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.discord_lambda_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.discord_lambda_logs.arn
}

# =============================================================================
# Parameter Store Outputs (conditional)
# =============================================================================
output "parameter_store_arn" {
  description = "ARN of the Parameter Store parameter for Discord webhook URL (if created)"
  value       = var.store_webhook_in_parameter_store ? aws_ssm_parameter.discord_webhook_url[0].arn : null
}

output "parameter_store_name" {
  description = "Name of the Parameter Store parameter for Discord webhook URL (if created)"
  value       = var.store_webhook_in_parameter_store ? aws_ssm_parameter.discord_webhook_url[0].name : null
}

# =============================================================================
# Monitoring Outputs
# =============================================================================
output "lambda_error_alarm_name" {
  description = "Name of the CloudWatch alarm for Lambda errors (if enabled)"
  value       = var.enable_lambda_monitoring ? aws_cloudwatch_metric_alarm.discord_lambda_errors[0].alarm_name : null
}

output "lambda_error_alarm_arn" {
  description = "ARN of the CloudWatch alarm for Lambda errors (if enabled)"
  value       = var.enable_lambda_monitoring ? aws_cloudwatch_metric_alarm.discord_lambda_errors[0].arn : null
}

# =============================================================================
# Usage Information
# =============================================================================
output "usage_instructions" {
  description = "Instructions on how to use this Discord notification module"
  value = {
    sns_topic_arn = aws_sns_topic.discord_notifications.arn
    usage_example = "To send a notification, publish a message to the SNS topic: aws sns publish --topic-arn ${aws_sns_topic.discord_notifications.arn} --message 'Your notification message'"
    supported_formats = [
      "Plain text messages",
      "JSON messages with title and description",
      "CloudWatch alarm notifications",
      "CodePipeline notifications"
    ]
  }
} 