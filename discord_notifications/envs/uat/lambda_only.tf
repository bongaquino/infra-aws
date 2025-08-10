# =============================================================================
# UAT Lambda Function for Discord Notifications (Clean Naming)
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create SNS Topic with Clean Name
resource "aws_sns_topic" "uat_discord_notifications" {
  name = "bongaquino-uat-discord-notifications"

  tags = {
    Environment = "uat"
    ManagedBy   = "terraform"
    Name        = "bongaquino-uat-discord-notifications"
    Owner       = "devops"
    Project     = "bongaquino"
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
resource "aws_iam_role" "uat_discord_lambda_role" {
  name = "bongaquino-uat-discord-lambda-role"

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
    Environment = "uat"
    ManagedBy   = "terraform"
    Name        = "bongaquino-uat-discord-lambda-role"
    Owner       = "devops"
    Project     = "bongaquino"
    Purpose     = "discord-notifications"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "uat_discord_lambda_policy" {
  name = "bongaquino-uat-discord-lambda-policy"
  role = aws_iam_role.uat_discord_lambda_role.id

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
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/bongaquino/uat/discord/*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "uat_discord_lambda_logs" {
  name              = "/aws/lambda/bongaquino-uat-discord-notifier"
  retention_in_days = 7

  tags = {
    Environment = "uat"
    ManagedBy   = "terraform"
    Name        = "bongaquino-uat-discord-lambda-logs"
    Owner       = "devops"
    Project     = "bongaquino"
    Purpose     = "discord-notifications"
  }
}

# Lambda Function with Clean Naming
resource "aws_lambda_function" "uat_discord_notifier" {
  filename         = "../../lambda/discord_notifier.zip"
  function_name    = "bongaquino-uat-discord-notifier"  # CLEAN NAME!
  role            = aws_iam_role.uat_discord_lambda_role.arn
  handler         = "discord_notifier.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 128
  source_code_hash = data.archive_file.discord_notifier_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
      DEFAULT_USERNAME    = "🔵 bongaquino UAT Bot"
      DEFAULT_AVATAR_URL  = "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original.svg"
      ENVIRONMENT         = "uat"
      PROJECT             = "bongaquino"
      
      # Color configuration
      SUCCESS_COLOR      = var.success_message_color
      WARNING_COLOR      = var.warning_message_color
      CRITICAL_COLOR     = var.critical_message_color
      DEFAULT_COLOR      = var.message_color
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.uat_discord_lambda_logs
  ]

  tags = {
    Environment = "uat"
    ManagedBy   = "terraform"
    Module      = "discord-notifications"
    Name        = "bongaquino-uat-discord-notifier"
    Owner       = "devops"
    Project     = "bongaquino"
    Purpose     = "Send notifications to Discord"
  }
}

# Lambda permission to allow SNS to invoke
resource "aws_lambda_permission" "uat_allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.uat_discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.uat_discord_notifications.arn
}

# SNS Topic Subscription to Lambda
resource "aws_sns_topic_subscription" "uat_discord_lambda" {
  topic_arn = aws_sns_topic.uat_discord_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.uat_discord_notifier.arn
}

# CloudWatch Metric Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "uat_discord_lambda_errors" {
  alarm_name          = "bongaquino-uat-discord-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Discord Lambda function errors"
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = aws_lambda_function.uat_discord_notifier.function_name
  }

  tags = {
    Environment = "uat"
    ManagedBy   = "terraform"
    Name        = "bongaquino-uat-discord-lambda-errors"
    Owner       = "devops"
    Project     = "bongaquino"
    Purpose     = "discord-notifications"
  }
} 