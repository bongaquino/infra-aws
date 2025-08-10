# =============================================================================
# Custom Application Monitoring for Go Backend
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "bongaquino-${var.environment}-discord-notifications"
}

# =============================================================================
# Custom CloudWatch Metrics and Alarms
# =============================================================================

# API Response Time Monitoring
resource "aws_cloudwatch_metric_alarm" "api_response_time" {
  alarm_name          = "bongaquino-${var.environment}-api-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApiResponseTime"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = var.api_response_time_threshold
  alarm_description   = "API response time is too high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-api-response-time"
    Environment = var.environment
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# File Upload Success Rate
resource "aws_cloudwatch_metric_alarm" "file_upload_success_rate" {
  alarm_name          = "bongaquino-${var.environment}-file-upload-success-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FileUploadSuccessRate"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "95"  # 95% success rate threshold
  alarm_description   = "File upload success rate is below threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-file-upload-success-rate"
    Environment = var.environment
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# Database Connection Pool Monitoring
resource "aws_cloudwatch_metric_alarm" "db_connection_pool" {
  alarm_name          = "bongaquino-${var.environment}-db-connection-pool"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnectionPoolUtilization"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # 80% connection pool utilization
  alarm_description   = "Database connection pool utilization is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-db-connection-pool"
    Environment = var.environment
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# Active Users Monitoring (for capacity planning)
resource "aws_cloudwatch_metric_alarm" "active_users_spike" {
  alarm_name          = "bongaquino-${var.environment}-active-users-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ActiveUsers"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.active_users_threshold
  alarm_description   = "Sudden spike in active users - potential viral growth or attack"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-active-users-spike"
    Environment = var.environment
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# Memory Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "memory_usage" {
  alarm_name          = "bongaquino-${var.environment}-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"  # 85% memory usage
  alarm_description   = "Application memory usage is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-memory-usage"
    Environment = var.environment
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Custom Log-based Metrics
# =============================================================================

# Panic/Fatal Error Detection
resource "aws_cloudwatch_log_metric_filter" "application_panics" {
  name           = "bongaquino-${var.environment}-application-panics"
  log_group_name = "/ecs/bongaquino-${var.environment}"
  pattern        = "[timestamp, level=\"PANIC\" || level=\"FATAL\", ...]"

  metric_transformation {
    name      = "ApplicationPanics"
    namespace = "bongaquino/Application"
    value     = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "application_panics" {
  alarm_name          = "bongaquino-${var.environment}-application-panics"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApplicationPanics"
  namespace           = "bongaquino/Application"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "🚨 CRITICAL: Application panic detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "bongaquino-${var.environment}-application-panics"
    Environment = var.environment
    Project     = "bongaquino"
    AlertLevel  = "CRITICAL"
    ManagedBy   = "terraform"
  }
}

# Slow Query Detection
resource "aws_cloudwatch_log_metric_filter" "slow_database_queries" {
  name           = "bongaquino-${var.environment}-slow-queries"
  log_group_name = "/ecs/bongaquino-${var.environment}"
  pattern        = "[timestamp, level, message=\"*slow query*\" || message=\"*query timeout*\", ...]"

  metric_transformation {
    name      = "SlowDatabaseQueries"
    namespace = "bongaquino/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "slow_database_queries" {
  alarm_name          = "bongaquino-${var.environment}-slow-database-queries"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SlowDatabaseQueries"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"  # More than 5 slow queries in 5 minutes
  alarm_description   = "Database performance degradation detected"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "bongaquino-${var.environment}-slow-database-queries"
    Environment = var.environment
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# Authentication Failure Monitoring
resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "bongaquino-${var.environment}-auth-failures"
  log_group_name = "/ecs/bongaquino-${var.environment}"
  pattern        = "[timestamp, level, message=\"*authentication failed*\" || message=\"*unauthorized*\" || message=\"*invalid token*\", ...]"

  metric_transformation {
    name      = "AuthenticationFailures"
    namespace = "bongaquino/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "auth_failures" {
  alarm_name          = "bongaquino-${var.environment}-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AuthenticationFailures"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "20"  # More than 20 auth failures in 5 minutes
  alarm_description   = "High number of authentication failures - potential brute force attack"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "bongaquino-${var.environment}-auth-failures"
    Environment = var.environment
    Project     = "bongaquino"
    AlertLevel  = "HIGH"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# Business Metrics Monitoring
# =============================================================================

# Daily Active Users Drop
resource "aws_cloudwatch_metric_alarm" "dau_drop" {
  alarm_name          = "bongaquino-${var.environment}-dau-drop"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DailyActiveUsers"
  namespace           = "bongaquino/Business"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = var.min_daily_active_users
  alarm_description   = "Daily active users below expected threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Name        = "bongaquino-${var.environment}-dau-drop"
    Environment = var.environment
    Project     = "bongaquino"
    AlertType   = "BUSINESS"
    ManagedBy   = "terraform"
  }
}

# File Storage Growth Rate
resource "aws_cloudwatch_metric_alarm" "storage_growth_rate" {
  alarm_name          = "bongaquino-${var.environment}-storage-growth-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StorageGrowthRate"
  namespace           = "bongaquino/Business"
  period              = "86400"  # 24 hours
  statistic           = "Sum"
  threshold           = var.max_daily_storage_growth_gb
  alarm_description   = "Storage growth rate exceeds expected threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Name        = "bongaquino-${var.environment}-storage-growth-rate"
    Environment = var.environment
    Project     = "bongaquino"
    AlertType   = "CAPACITY"
    ManagedBy   = "terraform"
  }
} 

# =============================================================================
# STAGING SERVER MONITORING - Server 52.77.36.120
# =============================================================================

# Server CPU Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "server_cpu_usage" {
  alarm_name          = "bongaquino-${var.environment}-server-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ServerCPUUsage"
  namespace           = "bongaquino/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # 80% CPU usage
  alarm_description   = "⚠️ Staging server CPU usage is high (>80%)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-server-cpu-usage"
    Environment = var.environment
    Project     = "bongaquino"
    AlertType   = "SERVER"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
}

# Server Memory Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "server_memory_usage" {
  alarm_name          = "bongaquino-${var.environment}-server-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ServerMemoryUsage"
  namespace           = "bongaquino/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"  # 85% memory usage
  alarm_description   = "🚨 CRITICAL: Staging server memory usage is critically high (>85%)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-server-memory-usage"
    Environment = var.environment
    Project     = "bongaquino"
    AlertType   = "SERVER"
    AlertLevel  = "CRITICAL"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
}

# Server Disk Usage Monitoring
resource "aws_cloudwatch_metric_alarm" "server_disk_usage" {
  alarm_name          = "bongaquino-${var.environment}-server-disk-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ServerDiskUsage"
  namespace           = "bongaquino/Server"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"  # 90% disk usage
  alarm_description   = "🚨 CRITICAL: Staging server disk space is critically low (>90%)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-server-disk-usage"
    Environment = var.environment
    Project     = "bongaquino"
    AlertType   = "SERVER"
    AlertLevel  = "CRITICAL"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
}

# Docker Container Health Monitoring
resource "aws_cloudwatch_metric_alarm" "docker_container_health" {
  for_each = toset(["server", "gateway", "mongo", "redis", "nginx-proxy"])
  
  alarm_name          = "bongaquino-${var.environment}-docker-${each.key}-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DockerContainerHealth"
  namespace           = "bongaquino/Docker"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"  # Less than 1 means unhealthy
  alarm_description   = "🚨 CRITICAL: Docker container '${each.key}' is unhealthy or down"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment   = var.environment
    Service       = "bongaquino-backend"
    ContainerName = each.key
  }

  tags = {
    Name         = "bongaquino-${var.environment}-docker-${each.key}-health"
    Environment  = var.environment
    Project      = "bongaquino"
    AlertType    = "DOCKER"
    AlertLevel   = "CRITICAL"
    Container    = each.key
    ServerIP     = "52.77.36.120"
    ManagedBy    = "terraform"
  }
}

# Backend API Health Check
resource "aws_cloudwatch_metric_alarm" "backend_api_health" {
  alarm_name          = "bongaquino-${var.environment}-backend-api-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApiResponseTime"
  namespace           = "bongaquino/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds response time
  alarm_description   = "🚨 Backend API is slow or unresponsive (>5s response time)"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    Environment = var.environment
    Service     = "bongaquino-backend"
    Endpoint    = "/"
  }

  tags = {
    Name        = "bongaquino-${var.environment}-backend-api-health"
    Environment = var.environment
    Project     = "bongaquino"
    AlertType   = "API"
    ServerIP    = "52.77.36.120"
    ManagedBy   = "terraform"
  }
} 