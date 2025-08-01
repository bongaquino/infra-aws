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
# Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# =============================================================================
# DynamoDB Table
# =============================================================================
resource "aws_dynamodb_table" "main" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  hash_key       = var.hash_key
  range_key      = var.range_key
  stream_enabled = var.stream_enabled
  stream_view_type = var.stream_enabled ? "NEW_AND_OLD_IMAGES" : null

  dynamic "point_in_time_recovery" {
    for_each = var.point_in_time_recovery_enabled ? [1] : []
    content {
    enabled = true
    }
  }

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
      type = "S"
    }
  }

  dynamic "attribute" {
    for_each = var.global_secondary_indexes
    content {
      name = attribute.value.hash_key
      type = "S"
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      read_capacity      = global_secondary_index.value.read_capacity
      write_capacity     = global_secondary_index.value.write_capacity
    }
  }

  tags = merge(var.tags, {
    Name = var.table_name
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# DynamoDB VPC Endpoint (Optional)
# =============================================================================
resource "aws_vpc_endpoint" "dynamodb" {
  count              = var.vpc_id != null ? 1 : 0
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = var.data_private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-dynamodb-endpoint"
  })
}

# =============================================================================
# DynamoDB Autoscaling
# =============================================================================
resource "aws_appautoscaling_target" "read_target" {
  count              = var.billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.max_read_capacity
  min_capacity       = var.min_read_capacity
  resource_id        = "table/${aws_dynamodb_table.main.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  count              = var.billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${var.project}-${var.environment}-read-capacity-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.target_read_capacity_utilization
  }
}

resource "aws_appautoscaling_target" "write_target" {
  count              = var.billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.max_write_capacity
  min_capacity       = var.min_write_capacity
  resource_id        = "table/${aws_dynamodb_table.main.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy" {
  count              = var.billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${var.project}-${var.environment}-write-capacity-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.target_write_capacity_utilization
  }
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "read_throttled_events" {
  alarm_name          = "${var.project}-${var.environment}-read-throttled-events"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors DynamoDB read throttled events"
  
  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "write_throttled_events" {
  alarm_name          = "${var.project}-${var.environment}-write-throttled-events"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors DynamoDB write throttled events"
  
  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }
  
  tags = var.tags
} 