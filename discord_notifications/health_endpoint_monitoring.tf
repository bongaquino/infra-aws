# =============================================================================
# Health Endpoint Monitoring with CloudWatch Synthetics
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "bongaquino-uat-discord-notifications"
}

# =============================================================================
# CloudWatch Synthetics Canary for Health Monitoring
# =============================================================================

# S3 Bucket for Canary artifacts
resource "aws_s3_bucket" "canary_artifacts" {
  bucket = "bongaquino-uat-canary-artifacts-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "bongaquino-uat-canary-artifacts"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_public_access_block" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  rule {
    id     = "delete_old_artifacts"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

# IAM Role for Synthetics Canary
resource "aws_iam_role" "canary_role" {
  name = "bongaquino-uat-health-canary-role"

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
    Name        = "bongaquino-uat-health-canary-role"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Canary Role
resource "aws_iam_role_policy" "canary_policy" {
  name = "bongaquino-uat-health-canary-policy"
  role = aws_iam_role.canary_role.id

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
        Resource = "arn:aws:logs:ap-southeast-1:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.canary_artifacts.arn,
          "${aws_s3_bucket.canary_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Synthetics Canary
resource "aws_synthetics_canary" "health_endpoint" {
  name                 = "bongaquino-uat-health-monitor"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.bucket}/canary-artifacts"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "apiCanaryBlueprint.handler"
  s3_bucket            = aws_s3_bucket.canary_artifacts.bucket
  s3_key               = aws_s3_object.canary_script.key
  s3_version           = aws_s3_object.canary_script.version_id
  runtime_version      = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds    = 60
    memory_in_mb         = 960
    active_tracing       = true
  }

  # Success percentage threshold
  success_retention_period = 30
  failure_retention_period = 30

  tags = {
    Name        = "bongaquino-uat-health-monitor"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }

  depends_on = [aws_s3_object.canary_script]
}

# Create the canary script as a data source
data "archive_file" "canary_script" {
  type        = "zip"
  output_path = "/tmp/bongaquino-health-canary.zip"
  
  source {
    content = templatefile("${path.module}/canary_scripts/health_monitor.js", {
      health_endpoint = "https://server-uat.example.com/check-health"
    })
    filename = "nodejs/node_modules/apiCanaryBlueprint.js"
  }
}

# Upload canary script to S3
resource "aws_s3_object" "canary_script" {
  bucket = aws_s3_bucket.canary_artifacts.bucket
  key    = "bongaquino-health-canary.zip"
  source = data.archive_file.canary_script.output_path
  etag   = data.archive_file.canary_script.output_md5

  depends_on = [data.archive_file.canary_script]
}

# =============================================================================
# CloudWatch Alarms for Canary
# =============================================================================

# Canary Success Rate Alarm
resource "aws_cloudwatch_metric_alarm" "canary_success_rate" {
  alarm_name          = "bongaquino-uat-health-endpoint-success-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CRITICAL: Health endpoint success rate is low"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]
  ok_actions          = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    CanaryName = aws_synthetics_canary.health_endpoint.name
  }

  tags = {
    Name        = "bongaquino-uat-health-endpoint-success-rate"
    Environment = "uat"
    Project     = "bongaquino"
    AlertLevel  = "CRITICAL"
    ManagedBy   = "terraform"
  }
}

# Canary Duration Alarm (Response Time)
resource "aws_cloudwatch_metric_alarm" "canary_duration" {
  alarm_name          = "bongaquino-uat-health-endpoint-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Duration"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000"  # 10 seconds
  alarm_description   = "WARNING: Health endpoint response time is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    CanaryName = aws_synthetics_canary.health_endpoint.name
  }

  tags = {
    Name        = "bongaquino-uat-health-endpoint-response-time"
    Environment = "uat"
    Project     = "bongaquino"
    AlertLevel  = "WARNING"
    ManagedBy   = "terraform"
  }
}

# Canary Failed Alarm
resource "aws_cloudwatch_metric_alarm" "canary_failed" {
  alarm_name          = "bongaquino-uat-health-endpoint-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Failed"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "CRITICAL: Health endpoint check failed"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]
  ok_actions          = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    CanaryName = aws_synthetics_canary.health_endpoint.name
  }

  tags = {
    Name        = "bongaquino-uat-health-endpoint-failures"
    Environment = "uat"
    Project     = "bongaquino"
    AlertLevel  = "CRITICAL"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Custom Metrics for Health Check Content Validation
# =============================================================================

# CloudWatch Log Group for Canary
resource "aws_cloudwatch_log_group" "canary_logs" {
  name              = "/aws/lambda/cwsyn-bongaquino-uat-health-monitor"
  retention_in_days = 14

  tags = {
    Name        = "bongaquino-uat-health-canary-logs"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# Metric filter for unhealthy responses
resource "aws_cloudwatch_log_metric_filter" "unhealthy_response" {
  name           = "bongaquino-uat-unhealthy-health-check"
  log_group_name = aws_cloudwatch_log_group.canary_logs.name
  pattern        = "{ $.healthy = false }"

  metric_transformation {
    name      = "UnhealthyHealthCheck"
    namespace = "bongaquino/HealthMonitoring"
    value     = "1"
  }
}

# Alarm for unhealthy responses
resource "aws_cloudwatch_metric_alarm" "unhealthy_response" {
  alarm_name          = "bongaquino-uat-health-endpoint-unhealthy"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnhealthyHealthCheck"
  namespace           = "bongaquino/HealthMonitoring"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CRITICAL: Health endpoint returning unhealthy status"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]
  ok_actions          = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "bongaquino-uat-health-endpoint-unhealthy"
    Environment = "uat"
    Project     = "bongaquino"
    AlertLevel  = "CRITICAL"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "canary_name" {
  description = "Name of the CloudWatch Synthetics canary"
  value       = aws_synthetics_canary.health_endpoint.name
}

output "canary_arn" {
  description = "ARN of the CloudWatch Synthetics canary"
  value       = aws_synthetics_canary.health_endpoint.arn
}

output "artifacts_bucket" {
  description = "S3 bucket for canary artifacts"
  value       = aws_s3_bucket.canary_artifacts.bucket
} 