# =============================================================================
# CodePipeline & CodeBuild Monitoring with Discord Alerts
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "koneksi-uat-discord-notifications"
}

# CodePipeline State Change Events
resource "aws_cloudwatch_event_rule" "codepipeline_state_change" {
  name        = "koneksi-uat-codepipeline-state-change"
  description = "Capture CodePipeline state changes"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = ["koneksi-uat-backend-pipeline"]
      state = ["SUCCEEDED", "FAILED", "STARTED", "CANCELED"]
    }
  })

  tags = {
    Name        = "koneksi-uat-codepipeline-state-change"
    Environment = "uat"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for CodePipeline State Changes
resource "aws_cloudwatch_event_target" "codepipeline_discord" {
  rule      = aws_cloudwatch_event_rule.codepipeline_state_change.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  # Removed input_transformer - let raw EventBridge events pass through
  # The Lambda function already knows how to handle native CodePipeline events
}

# CodeBuild Project State Change Events
resource "aws_cloudwatch_event_rule" "codebuild_state_change" {
  name        = "koneksi-uat-codebuild-state-change"
  description = "Capture CodeBuild project state changes"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      build-status = ["IN_PROGRESS", "SUCCEEDED", "FAILED", "STOPPED"]
    }
  })

  tags = {
    Name        = "koneksi-uat-codebuild-discord"
    Environment = "uat"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for CodeBuild State Changes
resource "aws_cloudwatch_event_target" "codebuild_discord" {
  rule      = aws_cloudwatch_event_rule.codebuild_state_change.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  # Removed input_transformer - let raw EventBridge events pass through
  # The Lambda function already knows how to handle native CodeBuild events
}

# ECR Image Scan Results
resource "aws_cloudwatch_event_rule" "ecr_scan_results" {
  name        = "koneksi-uat-ecr-scan-results"
  description = "Capture ECR image scan results"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Scan"]
    detail = {
      scan-status = ["COMPLETE"]
      repository-name = ["koneksi-uat-backend"]
    }
  })

  tags = {
    Name        = "koneksi-uat-ecr-scan-results"
    Environment = "uat"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for ECR Scan Results
resource "aws_cloudwatch_event_target" "ecr_scan_discord" {
  rule      = aws_cloudwatch_event_rule.ecr_scan_results.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  # Removed input_transformer - let raw EventBridge events pass through
  # The Lambda function already knows how to handle native ECR events
}

# CodePipeline Approval Actions
resource "aws_cloudwatch_event_rule" "codepipeline_approval" {
  name        = "koneksi-uat-codepipeline-approval"
  description = "Capture CodePipeline approval actions"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Stage Execution State Change"]
    detail = {
      pipeline = ["koneksi-uat-backend-pipeline"]
      stage = ["ApprovalStage"]
      state = ["STARTED", "SUCCEEDED", "FAILED"]
    }
  })

  tags = {
    Name        = "koneksi-uat-codepipeline-approval"
    Environment = "uat"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for CodePipeline Approval
resource "aws_cloudwatch_event_target" "codepipeline_approval_discord" {
  rule      = aws_cloudwatch_event_rule.codepipeline_approval.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  # Removed input_transformer - let raw EventBridge events pass through
  # The Lambda function already knows how to handle native CodePipeline events
}

# Grant EventBridge permission to publish to SNS
resource "aws_sns_topic_policy" "allow_eventbridge_to_discord" {
  arn = data.aws_sns_topic.discord_notifications.arn

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
        Resource = data.aws_sns_topic.discord_notifications.arn
      }
    ]
  })
} 