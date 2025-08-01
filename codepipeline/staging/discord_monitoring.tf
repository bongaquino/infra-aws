# =============================================================================
# CodePipeline & CodeBuild Monitoring with Discord Alerts for Staging
# =============================================================================

# Get the staging Discord SNS topic
data "aws_sns_topic" "staging_discord_notifications" {
  name = "koneksi-staging-discord-notifications"
}

# CodePipeline State Change Events
resource "aws_cloudwatch_event_rule" "codepipeline_state_change" {
  name        = "koneksi-staging-codepipeline-state-change"
  description = "Capture CodePipeline state changes for staging"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = ["koneksi-staging-deploy-pipeline"]
      state = ["SUCCEEDED", "FAILED", "STARTED", "CANCELED"]
    }
  })

  tags = {
    Name        = "koneksi-staging-codepipeline-state-change"
    Environment = "staging"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for CodePipeline State Changes
resource "aws_cloudwatch_event_target" "codepipeline_discord" {
  rule      = aws_cloudwatch_event_rule.codepipeline_state_change.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.staging_discord_notifications.arn
}

# CodeBuild Project State Change Events
resource "aws_cloudwatch_event_rule" "codebuild_state_change" {
  name        = "koneksi-staging-codebuild-state-change"
  description = "Capture CodeBuild project state changes for staging"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      project-name = ["koneksi-staging-deploy"]
      build-status = ["IN_PROGRESS", "SUCCEEDED", "FAILED", "STOPPED"]
    }
  })

  tags = {
    Name        = "koneksi-staging-codebuild-discord"
    Environment = "staging"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for CodeBuild State Changes
resource "aws_cloudwatch_event_target" "codebuild_discord" {
  rule      = aws_cloudwatch_event_rule.codebuild_state_change.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.staging_discord_notifications.arn
}

# Grant EventBridge permission to publish to SNS
resource "aws_sns_topic_policy" "allow_eventbridge_to_staging_discord" {
  arn = data.aws_sns_topic.staging_discord_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = data.aws_sns_topic.staging_discord_notifications.arn
      }
    ]
  })
}

# Outputs
output "staging_discord_sns_topic_arn" {
  description = "ARN of the staging Discord SNS topic"
  value       = data.aws_sns_topic.staging_discord_notifications.arn
}

output "staging_monitoring_setup" {
  description = "Staging monitoring setup status"
  value = {
    codepipeline_rule = aws_cloudwatch_event_rule.codepipeline_state_change.name
    codebuild_rule   = aws_cloudwatch_event_rule.codebuild_state_change.name
    sns_topic        = data.aws_sns_topic.staging_discord_notifications.name
    bot_name         = "Koneksi Staging Bot"
    environment      = "staging"
  }
} 