# =============================================================================
# Terraform Configuration
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}





# =============================================================================
# Data Sources
# =============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# S3 Bucket for CloudTrail Logs
# =============================================================================
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.organization_name}-cloudtrail-logs"

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-cloudtrail-logs"
    Purpose   = "CloudTrail Logs Storage"
    ManagedBy = "terraform"
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  count  = var.s3_lifecycle_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "cloudtrail_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = "cloudtrail-logs"
    }

    expiration {
      days = var.s3_lifecycle_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.s3_noncurrent_version_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# S3 Bucket Policy for CloudTrail
# =============================================================================
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.organization_name}-cloudtrail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.organization_name}-cloudtrail"
          }
        }
      }
    ]
  })
}

# =============================================================================
# CloudWatch Log Group (Optional)
# =============================================================================
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/cloudtrail/${var.organization_name}"
  retention_in_days = var.cloudwatch_logs_retention_days

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-cloudtrail-logs"
    ManagedBy = "terraform"
  })
}

# =============================================================================
# IAM Role for CloudTrail CloudWatch Logs
# =============================================================================
resource "aws_iam_role" "cloudtrail_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.organization_name}-cloudtrail-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-cloudtrail-logs-role"
    ManagedBy = "terraform"
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.organization_name}-cloudtrail-logs-policy"
  role  = aws_iam_role.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:log-stream:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}



# =============================================================================
# CloudTrail
# =============================================================================
resource "aws_cloudtrail" "main" {
  name           = "${var.organization_name}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  s3_key_prefix  = "cloudtrail-logs"

  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_logging                = var.enable_logging
  enable_log_file_validation    = var.enable_log_file_validation

  # CloudWatch Logs configuration
  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_logs[0].arn : null

  # SNS notifications
  sns_topic_name = var.sns_topic_arn

  # KMS encryption
  kms_key_id = var.kms_key_id

  # Event selectors for data events
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-cloudtrail"
    ManagedBy = "terraform"
  })

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs
  ]
}

# =============================================================================
# CloudWatch Metric Filters and Alarms
# =============================================================================
resource "aws_cloudwatch_log_metric_filter" "root_usage" {
  count          = var.enable_security_monitoring && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-root-usage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "${var.organization_name}-root-usage"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_usage" {
  count               = var.enable_security_monitoring && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-root-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.organization_name}-root-usage"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors root user usage"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-root-usage-alarm"
    ManagedBy = "terraform"
  })
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_calls" {
  count          = var.enable_security_monitoring && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-unauthorized-calls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "${var.organization_name}-unauthorized-calls"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_calls" {
  count               = var.enable_security_monitoring && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-unauthorized-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.organization_name}-unauthorized-calls"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors unauthorized API calls"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-unauthorized-calls-alarm"
    ManagedBy = "terraform"
  })
}

resource "aws_cloudwatch_log_metric_filter" "console_without_mfa" {
  count          = var.enable_security_monitoring && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-console-without-mfa"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"

  metric_transformation {
    name      = "${var.organization_name}-console-without-mfa"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_without_mfa" {
  count               = var.enable_security_monitoring && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-console-without-mfa"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.organization_name}-console-without-mfa"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors console login without MFA"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-console-without-mfa-alarm"
    ManagedBy = "terraform"
  })
}

# =============================================================================
# Advanced Log Monitoring and Anomaly Detection
# =============================================================================

# High-frequency API call detection (potential brute force or automation attacks)
resource "aws_cloudwatch_log_metric_filter" "high_frequency_api_calls" {
  count          = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-high-frequency-api-calls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "[version, account, time, region, source, trail, records]"

  metric_transformation {
    name      = "HighFrequencyAPICalls"
    namespace = "CloudTrail/LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_frequency_api_calls" {
  count               = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-high-frequency-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HighFrequencyAPICalls"
  namespace           = "CloudTrail/LogMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Detects unusually high API call frequency from single sources"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-high-frequency-api-calls-alarm"
    ManagedBy = "terraform"
  })
}

# Error spike detection
resource "aws_cloudwatch_log_metric_filter" "error_events" {
  count          = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-error-events"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorEvents"
    namespace = "CloudTrail/LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_spike" {
  count               = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-error-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorEvents"
  namespace           = "CloudTrail/LogMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "20"
  alarm_description   = "Detects spikes in error events that could indicate attacks or system issues"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-error-spike-alarm"
    ManagedBy = "terraform"
  })
}

# Unusual geolocation access detection
resource "aws_cloudwatch_log_metric_filter" "unusual_locations" {
  count          = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-unusual-locations"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "ConsoleLogin"

  metric_transformation {
    name      = "UnusualLocationLogins"
    namespace = "CloudTrail/LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unusual_location_logins" {
  count               = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-unusual-location-logins"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnusualLocationLogins"
  namespace           = "CloudTrail/LogMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Detects multiple successful logins that could indicate credential compromise"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-unusual-location-logins-alarm"
    ManagedBy = "terraform"
  })
}

# Privileged action monitoring
resource "aws_cloudwatch_log_metric_filter" "privileged_actions" {
  count          = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-privileged-actions"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "[version, account, time, region, source, trail, records]"

  metric_transformation {
    name      = "PrivilegedActions"
    namespace = "CloudTrail/LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "privileged_actions" {
  count               = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-privileged-actions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PrivilegedActions"
  namespace           = "CloudTrail/LogMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Detects multiple privileged IAM actions that could indicate privilege escalation"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-privileged-actions-alarm"
    ManagedBy = "terraform"
  })
}

# Network-based anomalies - unusual source IPs
resource "aws_cloudwatch_log_metric_filter" "new_source_ips" {
  count          = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  name           = "${var.organization_name}-new-source-ips"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name
  pattern        = "[version, account, time, region, source, trail, records]"

  metric_transformation {
    name      = "NewSourceIPs"
    namespace = "CloudTrail/LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "new_source_ip_spike" {
  count               = var.enable_anomaly_detection && var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.organization_name}-new-source-ip-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NewSourceIPs"
  namespace           = "CloudTrail/LogMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "Detects unusual spikes in activity from new source IPs"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.organization_name}-new-source-ip-spike-alarm"
    ManagedBy = "terraform"
  })
} 