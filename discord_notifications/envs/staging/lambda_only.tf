# =============================================================================
# Staging Lambda Function for Discord Notifications (Clean Naming)
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create SNS Topic with Clean Name
resource "aws_sns_topic" "staging_discord_notifications" {
  name = "koneksi-staging-discord-notifications"

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
    Name        = "koneksi-staging-discord-notifications"
    Owner       = "devops"
    Project     = "koneksi"
    Purpose     = "Discord webhook notifications"
  }
}

# Create zip file for Lambda
data "archive_file" "discord_notifier_zip" {
  type        = "zip"
  source_file = "../../lambda/discord_notifier.py"
  output_path = "../../lambda/discord_notifier.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "staging_discord_lambda_role" {
  name = "koneksi-staging-discord-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
    Name        = "koneksi-staging-discord-lambda-role"
    Owner       = "devops"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "staging_discord_lambda_policy" {
  name = "koneksi-staging-discord-lambda-policy"
  role = aws_iam_role.staging_discord_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/discord/*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "staging_discord_lambda_logs" {
  name              = "/aws/lambda/koneksi-staging-discord-notifier"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
    Name        = "koneksi-staging-discord-lambda-logs"
    Owner       = "devops"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
  }
}

# Lambda Function
resource "aws_lambda_function" "staging_discord_notifier" {
  filename         = "../../lambda/discord_notifier.zip"
  function_name    = "koneksi-staging-discord-notifier"  # CLEAN NAME!
  role            = aws_iam_role.staging_discord_lambda_role.arn
  handler         = "discord_notifier.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 128
  source_code_hash = data.archive_file.discord_notifier_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
      DEFAULT_USERNAME    = "Koneksi Staging Bot"
      DEFAULT_AVATAR_URL  = "https://example.com/staging-bot-avatar.png"
      ENVIRONMENT         = "staging"
      PROJECT             = "koneksi"
      
      # Color configuration
      SUCCESS_COLOR      = var.success_message_color
      WARNING_COLOR      = var.warning_message_color
      CRITICAL_COLOR     = var.critical_message_color
      DEFAULT_COLOR      = var.message_color
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.staging_discord_lambda_logs
  ]

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
    Module      = "discord-notifications"
    Name        = "koneksi-staging-discord-notifier"
    Owner       = "devops"
    Project     = "koneksi"
    Purpose     = "Send notifications to Discord"
  }
}

# Lambda permission to allow SNS to invoke
resource "aws_lambda_permission" "staging_allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.staging_discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.staging_discord_notifications.arn
}

# SNS Topic Subscription to Lambda
resource "aws_sns_topic_subscription" "staging_discord_lambda" {
  topic_arn = aws_sns_topic.staging_discord_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.staging_discord_notifier.arn
}

# CloudWatch Metric Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "staging_discord_lambda_errors" {
  count = var.enable_lambda_monitoring ? 1 : 0

  alarm_name          = "koneksi-staging-discord-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Discord Lambda function errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.staging_discord_notifier.function_name
  }

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
    Name        = "koneksi-staging-discord-lambda-errors"
    Owner       = "devops"
    Project     = "koneksi"
    Purpose     = "discord-notifications"
  }
} 