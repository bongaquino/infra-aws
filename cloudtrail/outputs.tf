# =============================================================================
# CloudTrail Outputs
# =============================================================================
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail"
  value       = aws_cloudtrail.main.name
}

output "cloudtrail_home_region" {
  description = "Home region of the CloudTrail"
  value       = aws_cloudtrail.main.home_region
}

# =============================================================================
# S3 Bucket Outputs
# =============================================================================
output "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.bucket_domain_name
}

# =============================================================================
# CloudWatch Logs Outputs
# =============================================================================
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "cloudtrail_logs_role_arn" {
  description = "ARN of the CloudTrail logs IAM role"
  value       = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_logs[0].arn : null
}



# =============================================================================
# Security Monitoring Outputs
# =============================================================================
output "security_alarm_names" {
  description = "Names of the security CloudWatch alarms"
  value = var.enable_security_monitoring ? {
    root_usage_alarm          = "${var.organization_name}-root-usage"
    unauthorized_calls_alarm  = "${var.organization_name}-unauthorized-calls"
    console_without_mfa_alarm = "${var.organization_name}-console-without-mfa"
  } : {}
}

output "metric_filter_names" {
  description = "Names of the CloudWatch log metric filters"
  value = var.enable_security_monitoring ? {
    root_usage_filter          = "${var.organization_name}-root-usage"
    unauthorized_calls_filter  = "${var.organization_name}-unauthorized-calls"
    console_without_mfa_filter = "${var.organization_name}-console-without-mfa"
  } : {}
}

# =============================================================================
# Advanced Monitoring and Anomaly Detection Outputs
# =============================================================================
output "anomaly_detection_alarm_names" {
  description = "Names of the advanced monitoring and anomaly detection alarms"
  value = var.enable_anomaly_detection ? {
    high_frequency_api_calls_alarm = "${var.organization_name}-high-frequency-api-calls"
    error_spike_alarm              = "${var.organization_name}-error-spike"
    unusual_location_logins_alarm  = "${var.organization_name}-unusual-location-logins"
    privileged_actions_alarm       = "${var.organization_name}-privileged-actions"
    new_source_ip_spike_alarm      = "${var.organization_name}-new-source-ip-spike"
  } : {}
}

output "anomaly_detection_metric_filters" {
  description = "Names of the anomaly detection metric filters"
  value = var.enable_anomaly_detection ? {
    high_frequency_api_calls_filter = "${var.organization_name}-high-frequency-api-calls"
    error_events_filter             = "${var.organization_name}-error-events"
    unusual_locations_filter        = "${var.organization_name}-unusual-locations"
    privileged_actions_filter       = "${var.organization_name}-privileged-actions"
    new_source_ips_filter          = "${var.organization_name}-new-source-ips"
  } : {}
} 