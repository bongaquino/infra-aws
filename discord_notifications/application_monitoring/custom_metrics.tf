# =============================================================================
# Custom Application Monitoring for Go Backend
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "koneksi-${var.environment}-discord-notifications"
}

# =============================================================================
# Custom CloudWatch Metrics and Alarms
# =============================================================================

# API Response Time Monitoring
resource "aws_cloudwatch_metric_alarm" "api_response_time" {
  alarm_name          = "koneksi-${var.environment}-api-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApiResponseTime"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = var.api_response_time_threshold
  alarm_description   = "API response time is too high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-api-response-time"
    Environment = var.environment
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# File Upload Success Rate
resource "aws_cloudwatch_metric_alarm" "file_upload_success_rate" {
  alarm_name          = "koneksi-${var.environment}-file-upload-success-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FileUploadSuccessRate"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "95"  # 95% success rate threshold
  alarm_description   = "File upload success rate is below threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-file-upload-success-rate"
    Environment = var.environment
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# Database Connection Pool Monitoring
resource "aws_cloudwatch_metric_alarm" "db_connection_pool" {
  alarm_name          = "koneksi-${var.environment}-db-connection-pool"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnectionPoolUtilization"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # 80% connection pool utilization
  alarm_description   = "Database connection pool utilization is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-db-connection-pool"
    Environment = var.environment
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# Active Users Monitoring (for capacity planning)
resource "aws_cloudwatch_metric_alarm" "active_users_spike" {
  alarm_name          = "koneksi-${var.environment}-active-users-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ActiveUsers"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.active_users_threshold
  alarm_description   = "Sudden spike in active users - potential viral growth or attack"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-active-users-spike"
    Environment = var.environment
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# Memory Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "memory_usage" {
  alarm_name          = "koneksi-${var.environment}-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"  # 85% memory usage
  alarm_description   = "Application memory usage is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-memory-usage"
    Environment = var.environment
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Custom Log-based Metrics
# =============================================================================

# Panic/Fatal Error Detection
resource "aws_cloudwatch_log_metric_filter" "application_panics" {
  name           = "koneksi-${var.environment}-application-panics"
  log_group_name = "/ecs/koneksi-${var.environment}"
  pattern        = "[timestamp, level=\"PANIC\" || level=\"FATAL\", ...]"

  metric_transformation {
    name      = "ApplicationPanics"
    namespace = "Koneksi/Application"
    value     = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "application_panics" {
  alarm_name          = "koneksi-${var.environment}-application-panics"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApplicationPanics"
  namespace           = "Koneksi/Application"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "🚨 CRITICAL: Application panic detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-${var.environment}-application-panics"
    Environment = var.environment
    Project     = "koneksi"
    AlertLevel  = "CRITICAL"
    ManagedBy   = "terraform"
  }
}

# Slow Query Detection
resource "aws_cloudwatch_log_metric_filter" "slow_database_queries" {
  name           = "koneksi-${var.environment}-slow-queries"
  log_group_name = "/ecs/koneksi-${var.environment}"
  pattern        = "[timestamp, level, message=\"*slow query*\" || message=\"*query timeout*\", ...]"

  metric_transformation {
    name      = "SlowDatabaseQueries"
    namespace = "Koneksi/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "slow_database_queries" {
  alarm_name          = "koneksi-${var.environment}-slow-database-queries"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SlowDatabaseQueries"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"  # More than 5 slow queries in 5 minutes
  alarm_description   = "Database performance degradation detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-${var.environment}-slow-database-queries"
    Environment = var.environment
    Project     = "koneksi"
    ManagedBy   = "terraform"
  }
}

# Authentication Failure Monitoring
resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "koneksi-${var.environment}-auth-failures"
  log_group_name = "/ecs/koneksi-${var.environment}"
  pattern        = "[timestamp, level, message=\"*authentication failed*\" || message=\"*unauthorized*\" || message=\"*invalid token*\", ...]"

  metric_transformation {
    name      = "AuthenticationFailures"
    namespace = "Koneksi/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "auth_failures" {
  alarm_name          = "koneksi-${var.environment}-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AuthenticationFailures"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "20"  # More than 20 auth failures in 5 minutes
  alarm_description   = "High number of authentication failures - potential brute force attack"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "koneksi-${var.environment}-auth-failures"
    Environment = var.environment
    Project     = "koneksi"
    AlertLevel  = "HIGH"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Business Metrics Monitoring
# =============================================================================

# Daily Active Users Drop
resource "aws_cloudwatch_metric_alarm" "dau_drop" {
  alarm_name          = "koneksi-${var.environment}-dau-drop"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DailyActiveUsers"
  namespace           = "Koneksi/Business"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = var.min_daily_active_users
  alarm_description   = "Daily active users below expected threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Name        = "koneksi-${var.environment}-dau-drop"
    Environment = var.environment
    Project     = "koneksi"
    AlertType   = "BUSINESS"
    ManagedBy   = "terraform"
  }
}

# File Storage Growth Rate
resource "aws_cloudwatch_metric_alarm" "storage_growth_rate" {
  alarm_name          = "koneksi-${var.environment}-storage-growth-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StorageGrowthRate"
  namespace           = "Koneksi/Business"
  period              = "86400"  # 24 hours
  statistic           = "Sum"
  threshold           = var.max_daily_storage_growth_gb
  alarm_description   = "Storage growth rate exceeds expected threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Name        = "koneksi-${var.environment}-storage-growth-rate"
    Environment = var.environment
    Project     = "koneksi"
    AlertType   = "CAPACITY"
    ManagedBy   = "terraform"
  }
} 

# =============================================================================
# STAGING SERVER MONITORING - Server 52.77.36.120
# =============================================================================

# Server CPU Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "server_cpu_usage" {
  alarm_name          = "koneksi-${var.environment}-server-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ServerCPUUsage"
  namespace           = "Koneksi/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # 80% CPU usage
  alarm_description   = "⚠️ Staging server CPU usage is high (>80%)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-server-cpu-usage"
    Environment = var.environment
    Project     = "koneksi"
    AlertType   = "SERVER"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
}

# Server Memory Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "server_memory_usage" {
  alarm_name          = "koneksi-${var.environment}-server-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ServerMemoryUsage"
  namespace           = "Koneksi/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"  # 85% memory usage
  alarm_description   = "🚨 CRITICAL: Staging server memory usage is critically high (>85%)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-server-memory-usage"
    Environment = var.environment
    Project     = "koneksi"
    AlertType   = "SERVER"
    AlertLevel  = "CRITICAL"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
}

# Server Disk Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "server_disk_usage" {
  alarm_name          = "koneksi-${var.environment}-server-disk-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ServerDiskUsage"
  namespace           = "Koneksi/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"  # 90% disk usage
  alarm_description   = "🚨 CRITICAL: Staging server disk space is critically low (>90%)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
  }

  tags = {
    Name        = "koneksi-${var.environment}-server-disk-usage"
    Environment = var.environment
    Project     = "koneksi"
    AlertType   = "SERVER"
    AlertLevel  = "CRITICAL"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
}

# Docker Container Health Monitoring
resource "aws_cloudwatch_metric_alarm" "docker_container_health" {
  for_each = toset(["server", "gateway", "mongo", "redis", "nginx-proxy"])
  
  alarm_name          = "koneksi-${var.environment}-docker-${each.key}-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DockerContainerHealth"
  namespace           = "Koneksi/Docker"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"  # Less than 1 means unhealthy
  alarm_description   = "🚨 CRITICAL: Docker container '${each.key}' is unhealthy or down"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment   = var.environment
    Service       = "koneksi-backend"
    ContainerName = each.key
  }

  tags = {
    Name         = "koneksi-${var.environment}-docker-${each.key}-health"
    Environment  = var.environment
    Project      = "koneksi"
    AlertType    = "DOCKER"
    AlertLevel   = "CRITICAL"
    Container    = each.key
    ServerIP     = "52.77.36.120"
    ManagedBy    = "terraform"
  }
}

# Backend API Health Check
resource "aws_cloudwatch_metric_alarm" "backend_api_health" {
  alarm_name          = "koneksi-${var.environment}-backend-api-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApiResponseTime"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds response time
  alarm_description   = "🚨 Backend API is slow or unresponsive (>5s response time)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "koneksi-backend"
    Endpoint    = "/"
  }

  tags = {
    Name        = "koneksi-${var.environment}-backend-api-health"
    Environment = var.environment
    Project     = "koneksi"
    AlertType   = "API"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
} 