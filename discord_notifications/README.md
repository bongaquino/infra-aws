# AWS Discord Notifications Module

This module provisions a comprehensive Discord notification system using AWS Lambda, SNS, and CloudWatch Events to deliver real-time, formatted alerts to Discord channels. It provides intelligent message formatting, multi-service integration, and enterprise-grade monitoring capabilities.

## Overview

The Discord Notifications module creates a centralized notification hub that automatically formats and delivers AWS service alerts, infrastructure monitoring, and application events to Discord channels. It supports rich message formatting, intelligent event filtering, and comprehensive monitoring across multiple environments.

## Features

- **Multi-Service Integration**: CloudWatch, CodePipeline, CodeBuild, ECS, and custom events
- **Intelligent Message Formatting**: Context-aware formatting with rich embeds and emojis
- **Event Filtering**: Smart filtering to prevent notification spam from unwanted events
- **Real-Time Delivery**: Immediate notification delivery via Discord webhooks
- **Rich Formatting**: Color-coded embeds with custom fields, timestamps, and links
- **Security & Compliance**: Secure webhook storage with encryption and least privilege access
- **Multi-Environment Support**: Environment-specific configurations and branding
- **Comprehensive Monitoring**: Built-in error tracking and performance monitoring
- **Custom Message Templates**: Support for custom structured and plain text messages
- **High Availability**: Fault-tolerant design with error handling and retry logic

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             AWS Services & Events                           │
│                                                                             │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────┐│
│ │   CloudWatch    │ │   CodePipeline  │ │   CodeBuild     │ │    ECS      ││
│ │     Alarms      │ │     Events      │ │    Events       │ │   Events    ││
│ └─────────┬───────┘ └─────────┬───────┘ └─────────┬───────┘ └─────┬───────┘│
│           │                   │                   │               │        │
└───────────┼───────────────────┼───────────────────┼───────────────┼────────┘
            │                   │                   │               │        
            └───────────────────┼───────────────────┼───────────────┘        
                                │                   │                        
                     ┌─────────▼───────────────────▼─┐                      
                     │         SNS Topic              │                      
                     │   (Discord Notifications)      │                      
                     │                                │                      
                     │ • Multi-service subscription   │                      
                     │ • Event filtering & routing    │                      
                     │ • Dead letter queue support    │                      
                     └─────────────┬──────────────────┘                      
                                   │                                         
                     ┌─────────────▼──────────────────┐                      
                     │        Lambda Function         │   ┌──────────────┐  
                     │     (Discord Notifier)         │──▶│  Parameter   │  
                     │                                │   │    Store     │  
                     │ • Intelligent message parsing │   │ (Webhook URL)│  
                     │ • Rich formatting & embeds    │   └──────────────┘  
                     │ • Event filtering logic       │                      
                     │ • Error handling & retries    │                      
                     │ • Performance optimization    │                      
                     └─────────────┬──────────────────┘                      
                                   │                                         
                     ┌─────────────▼──────────────────┐                      
                     │         Discord Channel        │                      
                     │                                │                      
                     │ • Real-time notifications      │                      
                     │ • Rich embeds with colors      │                      
                     │ • Contextual information       │                      
                     │ • Actionable links             │                      
                     └────────────────────────────────┘                      
                                   │                                         
              ┌────────────────────┼────────────────────┐                    
              │                    │                    │                    
    ┌─────────▼─────────┐ ┌───────▼───────┐ ┌─────────▼─────────┐            
    │  CloudWatch Logs  │ │   Monitoring  │ │     Alerting      │            
    │  (Lambda Logs)    │ │   Dashboard   │ │   (Error Alarms)  │            
    └───────────────────┘ └───────────────┘ └───────────────────┘            
```

### Key Components

1. **Event Sources**: Multiple AWS services generate events and alerts
2. **SNS Topic**: Central message hub with intelligent routing
3. **Lambda Function**: Processes and formats messages for Discord
4. **Discord Webhook**: Delivers formatted messages to Discord channels
5. **Parameter Store**: Secure storage for webhook URLs and configuration
6. **CloudWatch**: Comprehensive monitoring and logging

## Directory Structure

```
discord_notifications/
├── README.md                    # This documentation
├── main.tf                      # Core infrastructure resources
├── variables.tf                 # Input variables and configuration
├── outputs.tf                   # Module outputs
├── backend.tf                   # Backend configuration
├── lambda/
│   ├── discord_notifier.py      # Lambda function source code
│   └── discord_notifier.zip     # Packaged Lambda deployment
├── envs/                        # Environment-specific configurations
│   ├── staging/
│   │   ├── main.tf             # Staging environment setup
│   │   ├── variables.tf        # Staging-specific variables
│   │   ├── outputs.tf          # Staging outputs
│   │   └── backend.tf          # Staging backend configuration
│   └── uat/
│       ├── main.tf             # UAT environment setup
│       ├── variables.tf        # UAT-specific variables
│       ├── outputs.tf          # UAT outputs
│       └── backend.tf          # UAT backend configuration
└── monitoring/                  # Additional monitoring scripts
    ├── health_checks.sh        # Health monitoring scripts
    └── deployment_scripts/     # Automation scripts
```

## Resources Created

### Core Notification Infrastructure
- **aws_sns_topic**: Central notification hub with multi-service subscriptions
- **aws_lambda_function**: Discord message processor with rich formatting
- **aws_iam_role**: Service roles with least privilege access
- **aws_cloudwatch_log_group**: Lambda execution logs with configurable retention

### Monitoring & Alerting
- **aws_cloudwatch_metric_alarm**: Lambda error and performance monitoring
- **aws_cloudwatch_event_rule**: Event pattern matching for service integration
- **aws_sns_topic_subscription**: Lambda function subscription to SNS

### Security & Configuration
- **aws_ssm_parameter**: Optional secure storage for webhook URLs
- **aws_iam_policy**: Custom policies for service access
- **aws_lambda_permission**: SNS trigger permissions

## Quick Start

### 1. Get Discord Webhook URL

1. Go to your Discord server
2. Navigate to Server Settings → Integrations → Webhooks
3. Click "New Webhook" or "Create Webhook"
4. Configure the webhook:
   - Name: `bongaquino Notifications`
   - Channel: Select your desired channel
5. Copy the Webhook URL

### 2. Deploy the Module

```hcl
module "discord_notifications" {
  source = "./discord_notifications"

  # Required
  discord_webhook_url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
  environment        = "uat"
  project           = "bongaquino"

  # Optional customization
  discord_username   = "🔵 bongaquino UAT Bot"
  enable_mentions    = false
  log_retention_days = 7

  tags = {
    Environment = "uat"
    Project     = "bongaquino"
  }
}
```

### 3. Deploy Environment-Specific Configuration

```bash
cd bongaquino-aws/discord_notifications/envs/uat
terraform init
terraform plan -var="discord_webhook_url=YOUR_WEBHOOK_URL"
terraform apply
```

## Usage Examples

### 1. CloudWatch Alarms

Add the SNS topic ARN to your CloudWatch alarm actions:

```hcl
resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  # Send to Discord
  alarm_actions = [module.discord_notifications.sns_topic_arn]
}
```

### 2. Manual Notifications

Send a test message:

```bash
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-1:123456789012:bongaquino-uat-discord-notifications" \
  --message "Deployment completed successfully!" \
  --subject "UAT Deployment"
```

### 3. Custom Structured Messages

Send a custom formatted message:

```bash
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-1:123456789012:bongaquino-uat-discord-notifications" \
  --message '{
    "title": "Database Migration",
    "description": "Migration completed successfully for user table",
    "type": "success",
    "fields": [
      {
        "name": "Records Migrated",
        "value": "1,250",
        "inline": true
      },
      {
        "name": "Duration",
        "value": "2m 30s",
        "inline": true
      }
    ]
  }' \
  --subject "Database Update"
```

### 4. CodePipeline Integration

Configure CodePipeline to send notifications:

```hcl
resource "aws_codestarnotifications_notification_rule" "pipeline" {
  detail_type    = "FULL"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded"
  ]
  name     = "pipeline-notifications"
  resource = aws_codepipeline.example.arn

  target {
    address = module.discord_notifications.sns_topic_arn
  }
}
```

## Message Types and Colors

The module automatically applies appropriate colors and emojis:

| Type | Color | Emoji | Use Case |
|------|-------|-------|----------|
| `success` | Green | ✅ | Successful deployments, passing tests |
| `error` | Red | ❌ | Failed deployments, alarms |
| `warning` | Yellow | ⚠️ | Warnings, degraded performance |
| `info` | Blue | ℹ️ | General information |
| `critical` | Red | 🚨 | Critical alerts requiring immediate attention |

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project` | string | - | Project name for resource naming |
| `environment` | string | - | Environment name (staging/uat/prod) |
| `name_prefix` | string | - | Prefix for resource names |

### Discord Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `discord_webhook_url` | string | - | Discord webhook URL for notifications (sensitive) |
| `discord_username` | string | `"bongaquino Bot"` | Username displayed in Discord messages |
| `discord_avatar_url` | string | AWS logo | Avatar URL for Discord webhook messages |

### Message Formatting
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `message_color` | string | `"3447003"` | Default message color (blue) |
| `success_message_color` | string | `"3066993"` | Success message color (green) |
| `warning_message_color` | string | `"16776960"` | Warning message color (yellow) |
| `critical_message_color` | string | `"15158332"` | Critical message color (red) |

### Monitoring & Logging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_retention_days` | number | `14` | CloudWatch log retention period |
| `lambda_timeout` | number | `30` | Lambda function timeout in seconds |
| `enable_lambda_monitoring` | bool | `true` | Enable CloudWatch monitoring for Lambda |

### Security & Storage
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `store_webhook_in_parameter_store` | bool | `false` | Store webhook URL in Parameter Store |
| `enable_mentions` | bool | `false` | Enable @here/@everyone mentions for critical alerts |
| `kms_key_id` | string | `null` | KMS key ID for Parameter Store encryption |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `sns_topic_arn` | ARN of the SNS topic for Discord notifications |
| `sns_topic_name` | Name of the SNS topic |
| `lambda_function_arn` | ARN of the Discord notification Lambda function |
| `lambda_function_name` | Name of the Lambda function |
| `lambda_function_url` | Lambda function URL (if configured) |
| `log_group_name` | CloudWatch log group name for Lambda logs |
| `log_group_arn` | CloudWatch log group ARN |
| `iam_role_arn` | IAM role ARN for the Lambda function |

## Message Types & Formatting

### Supported Event Types

#### CloudWatch Alarms
```json
{
  "AlarmName": "high-cpu-usage",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 1 out of the last 1 datapoints...",
  "Region": "ap-southeast-1"
}
```
**Discord Output**: Rich embed with alarm status, metrics, and direct links to CloudWatch console.

#### CodePipeline Events
```json
{
  "source": "aws.codepipeline",
  "detail-type": "CodePipeline Pipeline Execution State Change",
  "detail": {
    "pipeline": "bongaquino-uat-backend-pipeline",
    "state": "SUCCEEDED"
  }
}
```
**Discord Output**: Pipeline status with execution details, timing, and console links.

#### CodeBuild Events
```json
{
  "source": "aws.codebuild",
  "detail-type": "CodeBuild Build State Change",
  "detail": {
    "build-status": "SUCCEEDED",
    "project-name": "bongaquino-uat-backend-build"
  }
}
```
**Discord Output**: Build status with project details, duration, and build logs.

#### ECS Task State Changes
```json
{
  "source": "aws.ecs",
  "detail-type": "ECS Task State Change",
  "detail": {
    "lastStatus": "RUNNING",
    "clusterArn": "arn:aws:ecs:region:account:cluster/bongaquino-uat"
  }
}
```
**Discord Output**: Task status with cluster information, task definition, and console links.

### Message Color Coding

| Event Type | Color | Hex Code | Usage |
|------------|-------|----------|-------|
| **Success** | Green | `#2ECC71` | Successful deployments, passing health checks |
| **Warning** | Yellow | `#F39C12` | Performance warnings, minor issues |
| **Error** | Red | `#E74C3C` | Failed deployments, alarm triggers |
| **Info** | Blue | `#3498DB` | General information, status updates |
| **Critical** | Dark Red | `#8B0000` | Critical system failures, security alerts |

### Custom Message Structure

```json
{
  "title": "Custom Alert Title",
  "description": "Detailed description of the event",
  "type": "success|warning|error|info|critical",
  "fields": [
    {
      "name": "Field Name",
      "value": "Field Value",
      "inline": true
    }
  ],
  "timestamp": "2023-10-01T12:00:00Z",
  "url": "https://console.aws.amazon.com/..."
}
```

## Event Filtering & Processing

### Automatic Event Filtering

The module includes intelligent filtering to prevent notification spam:

#### Filtered Events (No Notifications)
- **ECR Image Scan Results**: Automatically filtered to prevent scan spam
- **ECS Service Scaling**: Normal auto-scaling events are suppressed
- **CloudWatch Metric Streams**: High-frequency metric updates
- **AWS Config Compliance**: Routine compliance checks

#### Processed Events (With Notifications)
- **Pipeline State Changes**: All CodePipeline execution states
- **Build Failures**: CodeBuild project failures and recoveries
- **Alarm State Changes**: CloudWatch alarm state transitions
- **Task Failures**: ECS task failures and restarts
- **Security Events**: CloudTrail security-related alerts

### Custom Filtering Configuration

```python
# Example: Add custom filtering in Lambda function
def should_filter_event(event_detail):
    """Custom filtering logic"""
    # Filter out specific CodeBuild projects
    if event_detail.get('project-name', '').endswith('-test'):
        return True
    
    # Filter out minor ECS events
    if event_detail.get('lastStatus') in ['PENDING', 'PROVISIONING']:
        return True
    
    return False
```

## Security Features

### Webhook Security
- **Sensitive Variables**: Webhook URLs marked as sensitive in Terraform
- **Parameter Store**: Optional encrypted storage for webhook URLs
- **KMS Encryption**: Customer-managed key encryption support
- **Access Controls**: Strict IAM policies with least privilege

### Network Security
- **VPC Support**: Lambda function can run in private subnets
- **Security Groups**: Configurable network access controls
- **Endpoint Encryption**: HTTPS-only communication with Discord
- **IP Restrictions**: Optional IP allowlisting for webhook access

### Configuration Security
```hcl
# Secure webhook storage
module "discord_notifications" {
  source = "./discord_notifications"
  
  # Store webhook securely
  store_webhook_in_parameter_store = true
  kms_key_id                      = aws_kms_key.discord.id
  
  # Restrict network access
  vpc_config = {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda.id]
  }
}
```

## Performance Optimization

### Lambda Performance
- **Memory Allocation**: Optimized for typical message processing (128MB)
- **Timeout Configuration**: 30-second timeout for reliable processing
- **Cold Start Optimization**: Minimal dependencies and efficient code
- **Concurrent Execution**: Supports high-throughput message processing

### Message Delivery
- **Batch Processing**: Handles multiple SNS records efficiently
- **Error Handling**: Comprehensive error handling with retries
- **Dead Letter Queue**: Failed messages preserved for debugging
- **Rate Limiting**: Respects Discord API rate limits

### Cost Optimization
```hcl
# Cost-optimized configuration
lambda_timeout      = 15  # Reduce timeout for simple messages
log_retention_days  = 7   # Shorter retention for cost savings

# Use reserved concurrency for predictable costs
reserved_concurrent_executions = 10
```

## Monitoring & Troubleshooting

### CloudWatch Metrics
- **Lambda Duration**: Message processing time
- **Lambda Errors**: Function execution errors
- **Lambda Invocations**: Total function invocations
- **Lambda Throttles**: Rate limiting occurrences

### Custom Alarms
```hcl
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "discord-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Discord Lambda function errors"
  
  dimensions = {
    FunctionName = module.discord_notifications.lambda_function_name
  }
}
```

### Debugging Commands
```bash
# Check Lambda function logs
aws logs tail /aws/lambda/bongaquino-staging-discord-notifier --follow

# Test SNS message delivery
aws sns publish \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --message "Test message" \
  --subject "Test Notification"

# Check Lambda function metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=bongaquino-staging-discord-notifier \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average

# Test Lambda function directly
aws lambda invoke \
  --function-name bongaquino-staging-discord-notifier \
  --payload '{"Records":[{"EventSource":"aws:sns","Sns":{"Message":"Test direct invoke"}}]}' \
  response.json
```

## Common Issues & Solutions

### Discord Messages Not Appearing
**Symptoms**: SNS publishes successfully but no Discord messages
**Solutions**:
1. Verify webhook URL is correct and active
2. Check Lambda function logs for errors
3. Test webhook URL manually with curl
4. Verify Discord channel permissions

### Lambda Function Timeouts
**Symptoms**: Lambda function times out processing messages
**Solutions**:
1. Increase Lambda timeout configuration
2. Optimize message processing logic
3. Check network connectivity issues
4. Review message size and complexity

### Missing Message Formatting
**Symptoms**: Messages appear as plain text instead of rich embeds
**Solutions**:
1. Verify message structure matches expected format
2. Check Lambda function environment variables
3. Test with known good message format
4. Review Discord webhook configuration

### High Costs
**Symptoms**: Unexpected Lambda or CloudWatch charges
**Solutions**:
1. Review log retention settings
2. Optimize message filtering
3. Implement message batching
4. Use cost allocation tags for tracking

## Best Practices

### Message Design
1. **Keep Messages Concise**: Focus on essential information
2. **Use Rich Formatting**: Leverage embeds and colors effectively
3. **Include Action Links**: Provide direct links to AWS console
4. **Contextual Information**: Include environment and service details
5. **Consistent Formatting**: Maintain consistent message structure

### Security
1. **Rotate Webhooks**: Regularly rotate Discord webhook URLs
2. **Least Privilege**: Use minimal IAM permissions
3. **Monitor Access**: Track webhook usage and access patterns
4. **Secure Storage**: Use Parameter Store for sensitive configuration
5. **Network Security**: Deploy in private subnets when possible

### Operational
1. **Environment Separation**: Use separate webhooks per environment
2. **Message Filtering**: Implement intelligent filtering to reduce noise
3. **Testing**: Regularly test notification delivery
4. **Documentation**: Maintain webhook and channel documentation
5. **Backup**: Keep backup webhook URLs for disaster recovery

## Integration Examples

### CodePipeline Integration
```hcl
resource "aws_cloudwatch_event_rule" "codepipeline_state_change" {
  name = "codepipeline-state-change"
  
  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["FAILED", "SUCCEEDED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "discord_notifications" {
  rule      = aws_cloudwatch_event_rule.codepipeline_state_change.name
  target_id = "DiscordNotifications"
  arn       = module.discord_notifications.sns_topic_arn
}
```

### CloudWatch Alarms Integration
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  
  alarm_actions = [module.discord_notifications.sns_topic_arn]
  ok_actions    = [module.discord_notifications.sns_topic_arn]
}
```

### Custom Application Integration
```bash
# Send custom notification from application
aws sns publish \
  --topic-arn "$DISCORD_SNS_TOPIC" \
  --message '{
    "title": "Deployment Complete",
    "description": "Application version 2.1.0 deployed successfully",
    "type": "success",
    "fields": [
      {"name": "Version", "value": "2.1.0", "inline": true},
      {"name": "Environment", "value": "Production", "inline": true},
      {"name": "Duration", "value": "3m 45s", "inline": true}
    ]
  }' \
  --subject "Deployment Notification"
```

## Dependencies

- **SNS**: Message routing and delivery
- **Lambda**: Message processing and formatting
- **CloudWatch**: Logging and monitoring
- **IAM**: Access control and permissions
- **Parameter Store**: Optional secure configuration storage
- **KMS**: Optional encryption for stored secrets

## Integration with Other Modules

- **CloudWatch**: Alarm and metric notifications
- **CodePipeline**: CI/CD pipeline status updates
- **CodeBuild**: Build status and failure notifications  
- **ECS**: Container service health and deployment status
- **CloudTrail**: Security event notifications
- **ALB**: Load balancer health and performance alerts

## Maintenance

- **Regular Testing**: Test notification delivery monthly
- **Webhook Rotation**: Rotate Discord webhooks quarterly
- **Log Review**: Review Lambda logs for errors and optimization
- **Cost Analysis**: Monitor Lambda and CloudWatch costs
- **Security Audits**: Regular IAM and access pattern reviews

## Support

For issues related to:
- **Configuration**: Review Terraform configuration and Discord webhook setup
- **Message Delivery**: Check Lambda logs and SNS topic configuration
- **Formatting**: Verify message structure and Lambda function logic
- **Performance**: Analyze CloudWatch metrics and optimize configuration
- **Security**: Review IAM policies and webhook access controls

 