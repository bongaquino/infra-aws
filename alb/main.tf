locals {
  name_prefix = "${var.project}-${var.environment}"
  alb_name    = var.alb_name != "" ? var.alb_name : "${local.name_prefix}-alb"
  secondary_alb_name = var.secondary_alb_name != "" ? var.secondary_alb_name : "${local.name_prefix}-alb-services"
}

# Main ALB
resource "aws_lb" "main" {
  count = var.create_secondary_alb ? 0 : 1

  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  idle_timeout       = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix != "" ? var.access_logs_prefix : "${local.name_prefix}-main-alb"
      enabled = true
    }
  }

  dynamic "connection_logs" {
    for_each = var.enable_connection_logs && var.connection_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.connection_logs_bucket
      prefix  = var.connection_logs_prefix != "" ? var.connection_logs_prefix : "${local.name_prefix}-main-alb-connections"
      enabled = true
    }
  }

  tags = {
    Name        = local.alb_name
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "http" {
  count = var.create_main_alb ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count = var.create_main_alb ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

# HTTPS Listener Rule for Rate Limiting
resource "aws_lb_listener_rule" "rate_limit_main" {
  count = var.create_main_alb && var.enable_rate_limiting ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({
        error   = "Rate limit exceeded"
        message = "Too many requests. Please try again later."
        retry_after = 60
      })
      status_code = "429"
    }
  }

  condition {
    path_pattern {
      values = ["/files/*", "/directories/*"]
    }
  }
}

# Main Target Group
resource "aws_lb_target_group" "main" {
  count = var.create_main_alb ? 1 : 0

  name        = "${local.name_prefix}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    interval            = var.health_check_interval
    matcher            = "200"
    path               = var.healthcheck_path
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = var.health_check_timeout
    unhealthy_threshold = var.unhealthy_threshold
  }

  # Request timeout configuration
  dynamic "stickiness" {
    for_each = var.enable_stickiness ? [1] : []
    content {
      type            = "lb_cookie"
      cookie_duration = var.stickiness_duration
      enabled         = true
    }
  }

  tags = {
    Name        = "${local.name_prefix}-tg"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Services ALB
resource "aws_lb" "secondary" {
  count = var.create_secondary_alb ? 1 : 0

  name               = local.secondary_alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  idle_timeout       = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix != "" ? var.access_logs_prefix : "${local.name_prefix}-services-alb"
      enabled = true
    }
  }

  dynamic "connection_logs" {
    for_each = var.enable_connection_logs && var.connection_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.connection_logs_bucket
      prefix  = var.connection_logs_prefix != "" ? var.connection_logs_prefix : "${local.name_prefix}-services-alb-connections"
      enabled = true
    }
  }

  tags = {
    Name        = local.secondary_alb_name
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Services ALB HTTP Listener (port 8080)
resource "aws_lb_listener" "secondary_http_8080" {
  count = var.create_secondary_alb ? 1 : 0

  load_balancer_arn = aws_lb.secondary[0].arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.existing_services[0].arn
  }
}

# Services ALB Listener Rule for Rate Limiting
resource "aws_lb_listener_rule" "rate_limit_secondary" {
  count = var.create_secondary_alb && var.enable_rate_limiting ? 1 : 0

  listener_arn = aws_lb_listener.secondary_http_8080[0].arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({
        error   = "Rate limit exceeded"
        message = "Too many file operations. Please try again later."
        retry_after = 120
      })
      status_code = "429"
    }
  }

  condition {
    path_pattern {
      values = ["/files/*", "/directories/*", "/clients/v1/files/*", "/clients/v1/directories/*"]
    }
  }
}

# Data source to reference existing target group
data "aws_lb_target_group" "existing_services" {
  count = var.create_secondary_alb ? 1 : 0
  arn   = "arn:aws:elasticloadbalancing:ap-southeast-1:985869370256:targetgroup/bongaquino-uat-tg-services-tyk/ba7930b4898155e0"
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  count = var.create_secondary_alb ? 1 : 0

  alarm_name          = "${local.name_prefix}-alb-4xx"
  alarm_description   = "This metric monitors ALB 4XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "HTTPCode_ELB_4XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Sum"
  threshold          = 50
  alarm_actions      = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.secondary[0].arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-alb-4xx-alarm"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.create_secondary_alb ? 1 : 0

  alarm_name          = "${local.name_prefix}-alb-5xx"
  alarm_description   = "This metric monitors ALB 5XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "HTTPCode_ELB_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Sum"
  threshold          = 10
  alarm_actions      = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.secondary[0].arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-alb-5xx-alarm"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  count = var.create_secondary_alb ? 1 : 0

  alarm_name          = "${local.name_prefix}-alb-latency"
  alarm_description   = "This metric monitors ALB target response time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Average"
  threshold          = 300  # 5 minutes threshold for large file operations
  alarm_actions      = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.secondary[0].arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-alb-latency-alarm"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Request Timeout Alarm
resource "aws_cloudwatch_metric_alarm" "alb_request_timeout" {
  count = var.create_secondary_alb ? 1 : 0

  alarm_name          = "${local.name_prefix}-alb-request-timeout"
  alarm_description   = "This metric monitors ALB request timeouts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "RequestCount"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Sum"
  threshold          = 10
  alarm_actions      = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.secondary[0].arn_suffix
    TargetGroup  = data.aws_lb_target_group.existing_services[0].arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-alb-request-timeout-alarm"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Rate Limiting Alarm (429 responses)
resource "aws_cloudwatch_metric_alarm" "alb_rate_limit" {
  count = var.create_secondary_alb ? 1 : 0

  alarm_name          = "${local.name_prefix}-alb-rate-limit"
  alarm_description   = "This metric monitors ALB 429 rate limit responses"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "HTTPCode_ELB_4XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Sum"
  threshold          = 20
  alarm_actions      = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = aws_lb.secondary[0].arn_suffix
  }

  tags = {
    Name        = "${local.name_prefix}-alb-rate-limit-alarm"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alarms"

  tags = {
    Name        = "${local.name_prefix}-alarms"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alarms" {
  arn = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alarms.arn
      }
    ]
  })
}

# CloudWatch Log Groups for ALB Logs
resource "aws_cloudwatch_log_group" "main_alb_access_logs" {
  count = var.create_main_alb && var.enable_access_logs ? 1 : 0

  name              = "/aws/applicationloadbalancer/${local.name_prefix}-main-alb/access-logs"
  retention_in_days = 30

  tags = {
    Name        = "${local.name_prefix}-main-alb-access-logs"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "main_alb_connection_logs" {
  count = var.create_main_alb && var.enable_connection_logs ? 1 : 0

  name              = "/aws/applicationloadbalancer/${local.name_prefix}-main-alb/connection-logs"
  retention_in_days = 30

  tags = {
    Name        = "${local.name_prefix}-main-alb-connection-logs"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "services_alb_access_logs" {
  count = var.create_secondary_alb && var.enable_access_logs ? 1 : 0

  name              = "/aws/applicationloadbalancer/${local.name_prefix}-services-alb/access-logs"
  retention_in_days = 30

  tags = {
    Name        = "${local.name_prefix}-services-alb-access-logs"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "services_alb_connection_logs" {
  count = var.create_secondary_alb && var.enable_connection_logs ? 1 : 0

  name              = "/aws/applicationloadbalancer/${local.name_prefix}-services-alb/connection-logs"
  retention_in_days = 30

  tags = {
    Name        = "${local.name_prefix}-services-alb-connection-logs"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Lambda function to process S3 logs and send to CloudWatch
resource "aws_lambda_function" "alb_logs_processor" {
  count = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) ? 1 : 0

  filename         = "alb_logs_processor.zip"
  function_name    = "${local.name_prefix}-${var.create_main_alb ? "main" : "services"}-alb-logs-processor"
  role            = aws_iam_role.lambda_logs_processor[0].arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      MAIN_ALB_ACCESS_LOG_GROUP     = var.create_main_alb && var.enable_access_logs ? aws_cloudwatch_log_group.main_alb_access_logs[0].name : ""
      MAIN_ALB_CONNECTION_LOG_GROUP = var.create_main_alb && var.enable_connection_logs ? aws_cloudwatch_log_group.main_alb_connection_logs[0].name : ""
      SERVICES_ALB_ACCESS_LOG_GROUP = var.create_secondary_alb && var.enable_access_logs ? aws_cloudwatch_log_group.services_alb_access_logs[0].name : ""
      SERVICES_ALB_CONNECTION_LOG_GROUP = var.create_secondary_alb && var.enable_connection_logs ? aws_cloudwatch_log_group.services_alb_connection_logs[0].name : ""
    }
  }

  tags = {
    Name        = "${local.name_prefix}-${var.create_main_alb ? "main" : "services"}-alb-logs-processor"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_logs_processor" {
  count = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) ? 1 : 0

  name = "${local.name_prefix}-${var.create_main_alb ? "main" : "services"}-lambda-logs-processor-role"

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
    Name        = "${local.name_prefix}-${var.create_main_alb ? "main" : "services"}-lambda-logs-processor-role"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# IAM policy for Lambda to write to CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs_processor" {
  count = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) ? 1 : 0

  name = "${local.name_prefix}-${var.create_main_alb ? "main" : "services"}-lambda-logs-processor-policy"
  role = aws_iam_role.lambda_logs_processor[0].id

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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.access_logs_bucket != "" ? "arn:aws:s3:::${var.access_logs_bucket}/*" : ""}"
      }
    ]
  })
}

# S3 bucket notification to trigger Lambda when new logs arrive
resource "aws_s3_bucket_notification" "alb_logs_notification" {
  count = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) && var.enable_s3_notifications ? 1 : 0

  bucket = var.access_logs_bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.alb_logs_processor[0].arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.create_main_alb ? "main-alb" : "services-alb"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# Lambda permission to allow S3 to invoke the function
resource "aws_lambda_permission" "allow_bucket" {
  count = (var.create_main_alb || var.create_secondary_alb) && (var.enable_access_logs || var.enable_connection_logs) && var.enable_s3_notifications ? 1 : 0

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alb_logs_processor[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.access_logs_bucket}"
} 