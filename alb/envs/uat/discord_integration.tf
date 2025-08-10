# =============================================================================
# Discord Integration for ALB Alarms
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "bongaquino-uat-discord-notifications"
} 