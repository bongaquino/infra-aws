# =============================================================================
# Dedicated Security Discord Bot - Account-Wide Security Monitoring
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create the security Lambda function zip file
data "archive_file" "security_discord_notifier_zip" {
  type        = "zip"
  source_file = "../lambda/discord_notifier.py"
  output_path = "../lambda/security_discord_notifier.zip"
}

# =============================================================================
# SNS Topic for Security Notifications
# =============================================================================
resource "aws_sns_topic" "security_discord_notifications" {
  name = "bongaquino-security-discord-notifications"

  tags = {
    Environment = "account-wide"
    ManagedBy   = "terraform"
    Name        = "bongaquino-security-discord-notifications"
    Owner       = "security"
    Project     = "bongaquino"
    Purpose     = "Security monitoring Discord notifications"
  }
}

# =============================================================================
# CloudWatch Log Group for Security Lambda
# =============================================================================
resource "aws_cloudwatch_log_group" "security_discord_lambda_logs" {
  name              = "/aws/lambda/bongaquino-security-discord-notifier"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = "account-wide"
    ManagedBy   = "terraform"
    Name        = "bongaquino-security-discord-logs"
    Owner       = "security"
    Project     = "bongaquino"
    Purpose     = "Security bot Lambda logs"
  }
}

# =============================================================================
# IAM Role for Security Lambda Function
# =============================================================================
resource "aws_iam_role" "security_discord_lambda_role" {
  name = "bongaquino-security-discord-lambda-role"

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
    Environment = "account-wide"
    ManagedBy   = "terraform"
    Name        = "bongaquino-security-discord-lambda-role"
    Owner       = "security"
    Project     = "bongaquino"
    Purpose     = "Security Discord bot Lambda execution role"
  }
}

# IAM Policy for Security Lambda Function
resource "aws_iam_role_policy" "security_discord_lambda_policy" {
  name = "bongaquino-security-discord-lambda-policy"
  role = aws_iam_role.security_discord_lambda_role.id

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/bongaquino-security-discord-notifier:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/bongaquino/security/*"
      }
    ]
  })
}

# =============================================================================
# Security Discord Lambda Function
# =============================================================================
resource "aws_lambda_function" "security_discord_notifier" {
  filename         = "../lambda/security_discord_notifier.zip"
  function_name    = "bongaquino-security-discord-notifier"
  role            = aws_iam_role.security_discord_lambda_role.arn
  handler         = "discord_notifier.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 128
  source_code_hash = data.archive_file.security_discord_notifier_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
      DEFAULT_USERNAME    = "🛡️ bongaquino Security Bot"
      DEFAULT_AVATAR_URL  = "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original.svg"
      ENVIRONMENT         = "security"
      PROJECT             = "bongaquino"
      
      # Security-themed colors
      SUCCESS_COLOR      = "65280"     # Green
      WARNING_COLOR      = "16776960"  # Orange
      CRITICAL_COLOR     = "15158332"  # Red
      DEFAULT_COLOR      = "9442302"   # Security purple
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.security_discord_lambda_logs
  ]

  tags = {
    Environment = "account-wide"
    ManagedBy   = "terraform"
    Module      = "security-discord-notifications"
    Name        = "bongaquino-security-discord-notifier"
    Owner       = "security"
    Project     = "bongaquino"
    Purpose     = "Send security alerts to Discord"
  }
}

# =============================================================================
# Lambda Permissions and Subscriptions
# =============================================================================

# Lambda permission to allow SNS to invoke
resource "aws_lambda_permission" "security_allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_discord_notifications.arn
}

# SNS Topic Subscription to Lambda
resource "aws_sns_topic_subscription" "security_discord_lambda" {
  topic_arn = aws_sns_topic.security_discord_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.security_discord_notifier.arn
}

# =============================================================================
# Optional: Parameter Store for Security Webhook URL
# =============================================================================
resource "aws_ssm_parameter" "security_discord_webhook_url" {
  count = var.store_webhook_in_parameter_store ? 1 : 0
  
  name  = "/bongaquino/security/discord/webhook_url"
  type  = "SecureString"
  value = var.discord_webhook_url

  description = "Discord webhook URL for security notifications"

  tags = {
    Environment = "account-wide"
    ManagedBy   = "terraform"
    Name        = "bongaquino-security-discord-webhook-url"
    Owner       = "security"
    Project     = "bongaquino"
    Purpose     = "Store Discord webhook URL securely"
  }
}

# =============================================================================
# CloudWatch Monitoring for Security Lambda
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "security_lambda_errors" {
  count = var.enable_lambda_monitoring ? 1 : 0

  alarm_name          = "bongaquino-security-discord-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Security Discord Lambda function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.security_discord_notifier.function_name
  }

  alarm_actions = var.alarm_actions

  tags = {
    Environment = "account-wide"
    ManagedBy   = "terraform"
    Name        = "bongaquino-security-discord-lambda-errors"
    Owner       = "security"
    Project     = "bongaquino"
    Purpose     = "Monitor security Discord bot health"
  }
} 