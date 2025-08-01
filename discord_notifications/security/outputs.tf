# =============================================================================
# Security Discord Bot Outputs
# =============================================================================

output "security_sns_topic_arn" {
  description = "ARN of the security SNS topic for Discord notifications"
  value       = aws_sns_topic.security_discord_notifications.arn
}

output "security_sns_topic_name" {
  description = "Name of the security SNS topic"
  value       = aws_sns_topic.security_discord_notifications.name
}

output "security_lambda_function_arn" {
  description = "ARN of the security Discord notification Lambda function"
  value       = aws_lambda_function.security_discord_notifier.arn
}

output "security_lambda_function_name" {
  description = "Name of the security Lambda function"
  value       = aws_lambda_function.security_discord_notifier.function_name
}

output "security_log_group_name" {
  description = "CloudWatch log group name for security Discord Lambda"
  value       = aws_cloudwatch_log_group.security_discord_lambda_logs.name
}

output "security_iam_role_arn" {
  description = "ARN of the security Lambda IAM role"
  value       = aws_iam_role.security_discord_lambda_role.arn
}

# =============================================================================
# Integration Information
# =============================================================================

output "cloudtrail_integration_info" {
  description = "Information for integrating with CloudTrail security monitoring"
  value = {
    sns_topic_arn    = aws_sns_topic.security_discord_notifications.arn
    bot_name         = "🛡️ Koneksi Security Bot"
    environment      = "account-wide"
    purpose          = "Security monitoring and compliance alerts"
    supported_alerts = [
      "CloudTrail security events",
      "GuardDuty findings", 
      "AWS Config compliance",
      "IAM policy changes",
      "Security group modifications",
      "Root user activity",
      "Failed login attempts",
      "Unauthorized API calls"
    ]
  }
}

output "test_command" {
  description = "Command to test the security Discord bot"
  value = "aws sns publish --topic-arn ${aws_sns_topic.security_discord_notifications.arn} --message '{\"title\":\"🧪 Security Bot Test\",\"description\":\"Testing security Discord notifications\",\"type\":\"test\"}' --profile koneksi"
} 