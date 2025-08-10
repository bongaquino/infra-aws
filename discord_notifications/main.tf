# =============================================================================
# Terraform Configuration
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# =============================================================================
# Provider Configuration
# =============================================================================
provider "aws" {
  region  = "ap-southeast-1"
  profile = "bongaquino"
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Archive the Lambda function code
data "archive_file" "discord_notifier_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/discord_notifier.py"
  output_path = "${path.module}/lambda/discord_notifier.zip"
}

# =============================================================================
# SNS Topic for Discord Notifications
# =============================================================================
resource "aws_sns_topic" "discord_notifications" {
  name = local.sns_topic_name

  tags = merge(local.common_tags, {
    Name    = local.sns_topic_name
    Purpose = "Discord webhook notifications"
  })
}

resource "aws_sns_topic_policy" "discord_notifications" {
  arn = aws_sns_topic.discord_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.discord_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowOtherAWSServicesToPublish"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "codepipeline.amazonaws.com",
            "codebuild.amazonaws.com"
          ]
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.discord_notifications.arn
      }
    ]
  })
}

# =============================================================================
# Lambda Function for Discord Webhook
# =============================================================================
resource "aws_lambda_function" "discord_notifier" {
  filename         = data.archive_file.discord_notifier_zip.output_path
  function_name    = local.lambda_function_name
  role            = aws_iam_role.discord_lambda_role.arn
  handler         = "discord_notifier.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  source_code_hash = data.archive_file.discord_notifier_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
      ENVIRONMENT        = var.environment
      PROJECT           = var.project
      DEFAULT_USERNAME   = var.discord_username
      DEFAULT_AVATAR_URL = var.discord_avatar_url
      
      # Color configuration
      SUCCESS_COLOR      = var.success_message_color
      WARNING_COLOR      = var.warning_message_color
      CRITICAL_COLOR     = var.critical_message_color
      DEFAULT_COLOR      = var.message_color
    }
  }

  tags = merge(local.common_tags, {
    Name    = local.lambda_function_name
    Purpose = "Send notifications to Discord"
  })
}

# =============================================================================
# CloudWatch Log Group for Lambda
# =============================================================================
resource "aws_cloudwatch_log_group" "discord_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.discord_notifier.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-discord-lambda-logs"
    ManagedBy = "terraform"
  })
}

# =============================================================================
# IAM Role for Lambda Function
# =============================================================================
resource "aws_iam_role" "discord_lambda_role" {
  name = "${var.name_prefix}-discord-lambda-role"

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

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-discord-lambda-role"
    ManagedBy = "terraform"
  })
}

# =============================================================================
# IAM Policies for Lambda Function
# =============================================================================
resource "aws_iam_role_policy" "discord_lambda_policy" {
  name = "${var.name_prefix}-discord-lambda-policy"
  role = aws_iam_role.discord_lambda_role.id

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

# =============================================================================
# SNS Topic Subscription
# =============================================================================
resource "aws_sns_topic_subscription" "discord_lambda" {
  topic_arn = aws_sns_topic.discord_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_notifier.arn
}

# =============================================================================
# Lambda Permission for SNS
# =============================================================================
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.discord_notifications.arn
}

# =============================================================================
# Optional: Parameter Store for Discord Webhook URL
# =============================================================================
resource "aws_ssm_parameter" "discord_webhook_url" {
  count = var.store_webhook_in_parameter_store ? 1 : 0
  
  name  = "/${var.project}/${var.environment}/discord/webhook_url"
  type  = "SecureString"
  value = var.discord_webhook_url

  description = "Discord webhook URL for ${var.environment} notifications"

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-discord-webhook-url"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# CloudWatch Metric Alarm for Lambda Errors
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "discord_lambda_errors" {
  count = var.enable_lambda_monitoring ? 1 : 0

  alarm_name          = "${var.name_prefix}-discord-lambda-errors"
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
    FunctionName = aws_lambda_function.discord_notifier.function_name
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-discord-lambda-errors"
    ManagedBy = "terraform"
  })
} 