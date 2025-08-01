# =============================================================================
# Security Monitoring with Discord Alerts
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "koneksi-uat-discord-notifications"
}

# =============================================================================
# High-Priority Security Alerts
# =============================================================================

# Root User Activity
resource "aws_cloudwatch_metric_alarm" "root_user_activity" {
  alarm_name          = "koneksi-security-root-user-activity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootUserActivity"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CRITICAL: Root user activity detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-security-root-user-activity"
    Environment = "uat"
    Project     = "koneksi"
    AlertLevel  = "CRITICAL"
    ManagedBy   = "terraform"
  }
}

# Failed Console Logins (Brute Force Detection)
resource "aws_cloudwatch_log_metric_filter" "failed_console_logins" {
  name           = "koneksi-security-failed-console-logins"
  log_group_name = "/aws/cloudtrail/koneksi-uat"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.responseElements.ConsoleLogin = Failure) }"

  metric_transformation {
    name      = "FailedConsoleLogins"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_console_logins" {
  alarm_name          = "koneksi-security-failed-console-logins"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedConsoleLogins"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Multiple failed console login attempts detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-security-failed-console-logins"
    Environment = "uat"
    Project     = "koneksi"
    AlertLevel  = "HIGH"
    ManagedBy   = "terraform"
  }
}

# Unauthorized API Calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "koneksi-security-unauthorized-api-calls"
  log_group_name = "/aws/cloudtrail/koneksi-uat"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "koneksi-security-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Unauthorized API calls detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-security-unauthorized-api-calls"
    Environment = "uat"
    Project     = "koneksi"
    AlertLevel  = "HIGH"
    ManagedBy   = "terraform"
  }
}

# IAM Policy Changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "koneksi-security-iam-policy-changes"
  log_group_name = "/aws/cloudtrail/koneksi-uat"
  pattern        = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy) }"

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "koneksi-security-iam-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChanges"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "IAM policy changes detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-security-iam-policy-changes"
    Environment = "uat"
    Project     = "koneksi"
    AlertLevel  = "MEDIUM"
    ManagedBy   = "terraform"
  }
}

# Security Group Changes  
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "koneksi-security-sg-changes"
  log_group_name = "/aws/cloudtrail/koneksi-uat"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  alarm_name          = "koneksi-security-sg-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChanges"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Security group changes detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-security-sg-changes"
    Environment = "uat"
    Project     = "koneksi"
    AlertLevel  = "MEDIUM"
    ManagedBy   = "terraform"
  }
}

# Network ACL Changes
resource "aws_cloudwatch_log_metric_filter" "network_acl_changes" {
  name           = "koneksi-security-nacl-changes"
  log_group_name = "/aws/cloudtrail/koneksi-uat"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"

  metric_transformation {
    name      = "NetworkACLChanges"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_acl_changes" {
  alarm_name          = "koneksi-security-nacl-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NetworkACLChanges"
  namespace           = "CloudTrail/SecurityMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Network ACL changes detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-security-nacl-changes"
    Environment = "uat"
    Project     = "koneksi"
    AlertLevel  = "MEDIUM"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# AWS Config Compliance Events
# =============================================================================

# AWS Config Non-Compliance Events
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  name        = "koneksi-security-config-compliance-change"
  description = "Capture AWS Config compliance changes"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      configRuleComplianceChangeEventType = ["NON_COMPLIANT"]
    }
  })

  tags = {
    Name        = "koneksi-security-config-compliance-change"
    Environment = "uat"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for Config Compliance
resource "aws_cloudwatch_event_target" "config_compliance_discord" {
  rule      = aws_cloudwatch_event_rule.config_compliance_change.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  input_transformer {
    input_paths = {
      rule_name = "$.detail.configRuleName"
      compliance_type = "$.detail.newEvaluationResult.complianceType"
      resource_type = "$.detail.resourceType"
      resource_id = "$.detail.resourceId"
      account = "$.account"
      region = "$.region"
      time = "$.time"
    }

    input_template = jsonencode({
      title = "📋 AWS Config Compliance Alert"
      description = "Resource '<resource_id>' is non-compliant with rule '<rule_name>'"
      type = "security"
      details = {
        "Rule Name" = "<rule_name>"
        "Compliance Type" = "<compliance_type>"
        "Resource Type" = "<resource_type>"
        "Resource ID" = "<resource_id>"
        "Account" = "<account>"
        "Region" = "<region>"
        "Time" = "<time>"
      }
    })
  }
}

# =============================================================================
# GuardDuty Integration (if enabled)
# =============================================================================

# GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "koneksi-security-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [4, 5, 6, 7, 8, 9, 10] # Medium to High severity
    }
  })

  tags = {
    Name        = "koneksi-security-guardduty-findings"
    Environment = "uat"
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for GuardDuty
resource "aws_cloudwatch_event_target" "guardduty_discord" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  input_transformer {
    input_paths = {
      finding_type = "$.detail.type"
      severity = "$.detail.severity"
      title = "$.detail.title"
      description = "$.detail.description"
      account = "$.detail.accountId"
      region = "$.detail.region"
      time = "$.detail.updatedAt"
    }

    input_template = jsonencode({
      title = "🛡️ GuardDuty Security Finding"
      description = "<title> (Severity: <severity>)"
      type = "security"
      details = {
        "Finding Type" = "<finding_type>"
        "Severity" = "<severity>"
        "Title" = "<title>"
        "Description" = "<description>"
        "Account" = "<account>"
        "Region" = "<region>"
        "Time" = "<time>"
      }
    })
  }
} 