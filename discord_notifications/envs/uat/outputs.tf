# =============================================================================
# Discord Notifications Custom Setup Outputs (Clean Naming)
# =============================================================================
output "sns_topic_arn" {
  description = "ARN of the SNS topic for Discord notifications"
  value       = aws_sns_topic.uat_discord_notifications.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for Discord notifications"
  value       = aws_sns_topic.uat_discord_notifications.name
}

output "lambda_function_arn" {
  description = "ARN of the Discord notification Lambda function"
  value       = aws_lambda_function.uat_discord_notifier.arn
}

output "lambda_function_name" {
  description = "Name of the Discord notification Lambda function"
  value       = aws_lambda_function.uat_discord_notifier.function_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.uat_discord_lambda_logs.name
}

output "parameter_store_name" {
  description = "Name of the Parameter Store parameter for Discord webhook URL (if created)"
  value       = "Not using parameter store - webhook configured directly in Lambda"
}

# =============================================================================
# Usage Information
# =============================================================================
output "usage_instructions" {
  description = "Instructions on how to use this Discord notification setup"
  value = {
    sns_topic_arn = aws_sns_topic.uat_discord_notifications.arn
    test_command  = "aws sns publish --topic-arn ${aws_sns_topic.uat_discord_notifications.arn} --message 'Test notification from UAT environment' --subject 'UAT Test'"
    integration_examples = {
      cloudwatch_alarm = "Add this SNS topic ARN to your CloudWatch alarm actions"
      codepipeline    = "Configure this SNS topic in your CodePipeline notification rules"
      custom_message  = "Send structured messages with: {\"title\": \"Custom Title\", \"description\": \"Message content\", \"type\": \"success\"}"
    }
    clean_naming_note = "✅ This setup uses CLEAN NAMING: koneksi-uat-discord-notifier (no double uat!)"
  }
} 