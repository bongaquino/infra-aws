# =============================================================================
# CodePipeline Integration for Staging Discord Notifications
# =============================================================================

# Reference our clean-named SNS topic from lambda_only.tf
# (no data source needed - using resource reference)

# CloudWatch Event Rule for CodePipeline State Changes
resource "aws_cloudwatch_event_rule" "codepipeline_state_change" {
  name        = "koneksi-staging-codepipeline-discord-notifications"
  description = "Capture CodePipeline state changes for Staging"

  event_pattern = jsonencode({
    source        = ["aws.codepipeline"]
    detail-type   = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = ["koneksi-staging-backend-pipeline"]
      state    = ["STARTED", "SUCCEEDED", "FAILED", "CANCELED", "SUPERSEDED"]
    }
  })

  tags = {
    Name        = "koneksi-staging-codepipeline-discord"
    Environment = "staging"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Event Rule for CodePipeline Stage Changes
resource "aws_cloudwatch_event_rule" "codepipeline_stage_change" {
  name        = "koneksi-staging-codepipeline-stage-discord-notifications"
  description = "Capture CodePipeline stage changes for Staging"

  event_pattern = jsonencode({
    source        = ["aws.codepipeline"]
    detail-type   = ["CodePipeline Stage Execution State Change"]
    detail = {
      pipeline = ["koneksi-staging-backend-pipeline"]
      state    = ["STARTED", "SUCCEEDED", "FAILED", "CANCELED"]
    }
  })

  tags = {
    Name        = "koneksi-staging-codepipeline-stage-discord"
    Environment = "staging"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Event Rule for CodePipeline Action Changes (for more detailed monitoring)
resource "aws_cloudwatch_event_rule" "codepipeline_action_change" {
  name        = "koneksi-staging-codepipeline-action-discord-notifications"
  description = "Capture CodePipeline action changes for Staging"

  event_pattern = jsonencode({
    source        = ["aws.codepipeline"]
    detail-type   = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = ["koneksi-staging-backend-pipeline"]
      state    = ["FAILED"]  # Only capture failed actions for noise reduction
    }
  })

  tags = {
    Name        = "koneksi-staging-codepipeline-action-discord"
    Environment = "staging"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target - Pipeline State Changes
resource "aws_cloudwatch_event_target" "codepipeline_state_sns" {
  rule      = aws_cloudwatch_event_rule.codepipeline_state_change.name
  target_id = "SendToDiscordSNS"
  arn       = aws_sns_topic.staging_discord_notifications.arn

  # Removed input_transformer - let raw EventBridge events pass through
  # The Lambda function already knows how to handle native CodePipeline events
}

# EventBridge Target - Stage Changes
resource "aws_cloudwatch_event_target" "codepipeline_stage_sns" {
  rule      = aws_cloudwatch_event_rule.codepipeline_stage_change.name
  target_id = "SendStageToDiscordSNS"
  arn       = aws_sns_topic.staging_discord_notifications.arn

  # Removed input_transformer - let raw EventBridge events pass through
  # The Lambda function already knows how to handle native CodePipeline events
}

# SNS Topic Policy to allow EventBridge to publish
resource "aws_sns_topic_policy" "codepipeline_eventbridge_policy" {
  arn = aws_sns_topic.staging_discord_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.staging_discord_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "985869370256"
          }
        }
      }
    ]
  })
} 