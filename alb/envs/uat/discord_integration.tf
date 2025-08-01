# =============================================================================
# Discord Integration for ALB Alarms
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "koneksi-uat-discord-notifications"
} 