# =============================================================================
# ECS Service Monitoring with Discord Alerts
# =============================================================================

# Get the Discord SNS topic
data "aws_sns_topic" "discord_notifications" {
  name = "bongaquino-uat-discord-notifications"
}

# ECS Service CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "bongaquino-uat-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ECS service CPU utilization is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    ServiceName = "bongaquino-uat-service"
    ClusterName = "bongaquino-uat-cluster"
  }

  tags = {
    Name        = "bongaquino-uat-ecs-cpu-high"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# ECS Service Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "bongaquino-uat-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "ECS service memory utilization is high"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    ServiceName = "bongaquino-uat-service"
    ClusterName = "bongaquino-uat-cluster"
  }

  tags = {
    Name        = "bongaquino-uat-ecs-memory-high"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# ECS Service Running Task Count Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_tasks_stopped" {
  alarm_name          = "bongaquino-uat-ecs-tasks-stopped"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "ECS service has stopped tasks"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  dimensions = {
    ServiceName = "bongaquino-uat-service"
    ClusterName = "bongaquino-uat-cluster"
  }

  tags = {
    Name        = "bongaquino-uat-ecs-tasks-stopped"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# ECS Service Task Definition Changes (EventBridge Rule)
resource "aws_cloudwatch_event_rule" "ecs_task_state_change" {
  name        = "bongaquino-uat-ecs-task-state-change"
  description = "Capture ECS task state changes"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn = ["arn:aws:ecs:ap-southeast-1:985869370256:cluster/bongaquino-uat-cluster"]
      lastStatus = ["STOPPED"]
      stoppedReason = [{
        "exists": true
      }]
    }
  })

  tags = {
    Name        = "bongaquino-uat-ecs-task-state-change"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
}

# EventBridge Target for ECS Task State Changes
resource "aws_cloudwatch_event_target" "ecs_task_state_discord" {
  rule      = aws_cloudwatch_event_rule.ecs_task_state_change.name
  target_id = "SendToDiscord"
  arn       = data.aws_sns_topic.discord_notifications.arn

  input_transformer {
    input_paths = {
      clusterArn = "$.detail.clusterArn"
      taskArn = "$.detail.taskArn"
      lastStatus = "$.detail.lastStatus"
      stoppedReason = "$.detail.stoppedReason"
      stoppedAt = "$.detail.stoppedAt"
    }

    input_template = "{\n  \"title\": \"🔴 ECS Task State Change\",\n  \"description\": \"ECS task <taskArn> has <lastStatus>\",\n  \"type\": \"warning\",\n  \"details\": {\n    \"Cluster\": \"<clusterArn>\",\n    \"Task ARN\": \"<taskArn>\",\n    \"Status\": \"<lastStatus>\",\n    \"Stopped Reason\": \"<stoppedReason>\",\n    \"Stopped At\": \"<stoppedAt>\",\n    \"Environment\": \"uat\"\n  }\n}"
  }
}

# CloudWatch Logs Error Detection
resource "aws_cloudwatch_log_metric_filter" "ecs_application_errors" {
  name           = "bongaquino-uat-ecs-application-errors"
  log_group_name = "/ecs/bongaquino-uat"
  pattern        = "ERROR"

  metric_transformation {
    name      = "ApplicationErrors"
    namespace = "bongaquino/ECS"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_application_errors" {
  alarm_name          = "bongaquino-uat-ecs-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationErrors"
  namespace           = "bongaquino/ECS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High number of application errors in ECS logs"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]

  tags = {
    Name        = "bongaquino-uat-ecs-application-errors"
    Environment = "uat"
    Project     = "bongaquino"
    ManagedBy   = "terraform"
  }
} 