# =============================================================================
# Discord Notifications Staging Setup Outputs (Clean Naming)
# =============================================================================
output "sns_topic_arn" {
  description = "ARN of the SNS topic for Discord notifications"
  value       = aws_sns_topic.staging_discord_notifications.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for Discord notifications"
  value       = aws_sns_topic.staging_discord_notifications.name
}

output "lambda_function_arn" {
  description = "ARN of the Discord notification Lambda function"
  value       = aws_lambda_function.staging_discord_notifier.arn
}

output "lambda_function_name" {
  description = "Name of the Discord notification Lambda function"
  value       = aws_lambda_function.staging_discord_notifier.function_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.staging_discord_lambda_logs.name
}

output "parameter_store_name" {
  description = "Name of the Parameter Store parameter for Discord webhook URL (if created)"
  value       = "Not using parameter store - webhook configured directly in Lambda"
}

# =============================================================================
# Usage Information
# =============================================================================
output "test_command" {
  description = "Command to test Discord notifications"
  value       = "aws sns publish --topic-arn ${aws_sns_topic.staging_discord_notifications.arn} --message 'Test message' --subject 'Staging Test'"
}

output "usage_guide" {
  description = "Quick usage guide for the Discord notifications"
  value = <<EOF
🟡 Koneksi Staging Bot Setup Complete!

✅ Discord Channel: #koneksi-alerts
✅ SNS Topic: ${aws_sns_topic.staging_discord_notifications.name}
✅ Lambda Function: ${aws_lambda_function.staging_discord_notifier.function_name}

🧪 Test Command:
aws sns publish --topic-arn ${aws_sns_topic.staging_discord_notifications.arn} --message "Test staging alert" --subject "Test"

📊 Monitor Logs:
aws logs tail ${aws_cloudwatch_log_group.staging_discord_lambda_logs.name} --follow
EOF
}

output "clean_naming_note" {
  description = "Information about the clean naming convention used"
  value       = "✅ This setup uses CLEAN NAMING: koneksi-staging-discord-notifier (no double staging!)"
} 