# Application Load Balancer (ALB) Module

This module provisions Application Load Balancers with advanced features including rate limiting, comprehensive monitoring, logging, and automated log processing for the Koneksi infrastructure.

## Overview

The ALB module supports dual load balancer configurations:
- **Main ALB**: HTTPS/HTTP traffic with SSL termination and redirect
- **Secondary ALB**: Services-specific traffic on port 8080

## Features

- **Dual ALB Support**: Main and secondary load balancers for different use cases
- **SSL/TLS Termination**: HTTPS listeners with automatic HTTP to HTTPS redirect
- **Rate Limiting**: Built-in protection against excessive requests
- **Comprehensive Monitoring**: CloudWatch alarms for errors, latency, and timeouts
- **Access Logging**: Detailed request logging to S3 and CloudWatch
- **Lambda Log Processing**: Automated log analysis and forwarding
- **Health Checks**: Configurable health monitoring for targets
- **Session Stickiness**: Optional session persistence
- **SNS Notifications**: Automated alerting for threshold breaches

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Internet      │    │   Main ALB      │    │   Target Group  │
│   Gateway       │───▶│   (443/80)      │───▶│   (ECS Tasks)   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │  Secondary ALB  │
                       │    (8080)       │────┐
                       └─────────────────┘    │
                              │              │
                              ▼              ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  CloudWatch     │    │   S3 Bucket     │
                       │  Alarms & Logs  │    │   Access Logs   │
                       └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   SNS Topic     │    │ Lambda Function │
                       │ (Notifications) │    │ (Log Processor) │
                       └─────────────────┘    └─────────────────┘
```

## Directory Structure

```
alb/
├── main.tf                  # Main ALB configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── alb_logs_processor.js    # Lambda function code
├── package.json             # Lambda dependencies
├── build_lambda.sh          # Build script for Lambda
├── *.zip                    # Lambda deployment packages
├── envs/                    # Environment-specific configurations
│   ├── staging/
│   ├── uat/
│   └── prod/
└── README.md               # This documentation
```

## Resources Created

### Load Balancers
- **aws_lb.main**: Main application load balancer (HTTPS/HTTP)
- **aws_lb.secondary**: Secondary load balancer for services (HTTP 8080)

### Listeners & Rules
- **aws_lb_listener.http**: HTTP listener (redirects to HTTPS)
- **aws_lb_listener.https**: HTTPS listener with SSL termination
- **aws_lb_listener.secondary_http_8080**: Services HTTP listener
- **aws_lb_listener_rule**: Rate limiting rules for both ALBs

### Target Groups
- **aws_lb_target_group.main**: Target group for main ALB
- **data.aws_lb_target_group.existing_services**: Reference to services target group

### Monitoring & Alerting
- **aws_cloudwatch_metric_alarm**: Multiple alarms for 4xx, 5xx, latency, timeouts
- **aws_sns_topic.alarms**: SNS topic for alarm notifications
- **aws_cloudwatch_log_group**: Log groups for access and connection logs

### Log Processing
- **aws_lambda_function.alb_logs_processor**: Processes S3 logs to CloudWatch
- **aws_iam_role.lambda_logs_processor**: IAM role for Lambda execution
- **aws_s3_bucket_notification**: Triggers Lambda on new log files

## Usage

### Basic Main ALB Configuration

```hcl
module "alb" {
  source = "./alb"
  
  # Basic settings
  region      = "ap-southeast-1"
  environment = "staging"
  project     = "koneksi"
  
  # Network configuration
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  
  # SSL configuration
  certificate_arn = module.acm.certificate_arn
  
  # Target configuration
  target_port       = 8080
  healthcheck_path  = "/health"
  
  # ALB selection
  create_main_alb      = true
  create_secondary_alb = false
}
```

### Dual ALB Configuration

```hcl
module "alb" {
  source = "./alb"
  
  # ... basic configuration ...
  
  # Enable both ALBs
  create_main_alb      = true
  create_secondary_alb = true
  
  # Custom names
  alb_name           = "koneksi-main-alb"
  secondary_alb_name = "koneksi-services-alb"
  
  # Advanced features
  enable_rate_limiting = true
  enable_access_logs   = true
  access_logs_bucket   = "koneksi-alb-logs"
  
  # Health check tuning
  health_check_timeout  = 30
  health_check_interval = 60
  healthy_threshold     = 2
  unhealthy_threshold   = 3
}
```

### Environment-Specific Deployment

1. **Navigate to ALB directory**:
```bash
cd koneksi-aws/alb
```

2. **Initialize Terraform**:
```bash
terraform init -backend-config=envs/staging/backend.tf
```

3. **Plan the deployment**:
```bash
AWS_PROFILE=koneksi terraform plan -var-file=envs/staging/terraform.tfvars
```

4. **Apply the configuration**:
```bash
AWS_PROFILE=koneksi terraform apply -var-file=envs/staging/terraform.tfvars
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | string | - | AWS region |
| `environment` | string | - | Environment name (staging/uat/prod) |
| `project` | string | - | Project name |
| `vpc_id` | string | - | VPC ID where ALB will be created |
| `public_subnet_ids` | list(string) | - | List of public subnet IDs for ALB |
| `alb_security_group_id` | string | - | Security group ID for ALB |
| `certificate_arn` | string | - | ARN of SSL/TLS certificate |

### ALB Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_main_alb` | bool | `true` | Whether to create main ALB |
| `create_secondary_alb` | bool | `false` | Whether to create secondary ALB |
| `alb_name` | string | `""` | Custom name for main ALB |
| `secondary_alb_name` | string | `""` | Custom name for secondary ALB |
| `idle_timeout` | number | `60` | ALB idle timeout (1-4000 seconds) |
| `enable_deletion_protection` | bool | `false` | Enable deletion protection |

### Target Group Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `target_port` | number | `8080` | Target port for health checks |
| `healthcheck_path` | string | `"/api"` | Health check path |
| `health_check_timeout` | number | `30` | Health check timeout (2-120s) |
| `health_check_interval` | number | `60` | Health check interval |
| `healthy_threshold` | number | `2` | Healthy threshold count |
| `unhealthy_threshold` | number | `3` | Unhealthy threshold count |
| `enable_stickiness` | bool | `true` | Enable session stickiness |
| `stickiness_duration` | number | `86400` | Session duration (seconds) |

### Rate Limiting & Security
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_rate_limiting` | bool | `true` | Enable rate limiting for file operations |

### Logging Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_access_logs` | bool | `false` | Enable ALB access logs |
| `access_logs_bucket` | string | `""` | S3 bucket for access logs |
| `access_logs_prefix` | string | `""` | S3 prefix for access logs |
| `enable_connection_logs` | bool | `false` | Enable connection logs |
| `connection_logs_bucket` | string | `""` | S3 bucket for connection logs |
| `connection_logs_prefix` | string | `""` | S3 prefix for connection logs |
| `enable_s3_notifications` | bool | `true` | Enable S3→Lambda notifications |

## Outputs

### Main ALB Outputs
| Output | Description |
|--------|-------------|
| `alb_dns_name` | DNS name of main ALB |
| `alb_arn` | ARN of main ALB |
| `alb_zone_id` | Route53 zone ID of main ALB |
| `target_group_arn` | ARN of main target group |

### Secondary ALB Outputs
| Output | Description |
|--------|-------------|
| `services_alb_dns_name` | DNS name of secondary ALB |
| `services_alb_arn` | ARN of secondary ALB |
| `services_alb_zone_id` | Route53 zone ID of secondary ALB |
| `services_target_group_arn` | ARN of services target group |
| `services_listener_arn` | ARN of services listener |

### Monitoring Outputs
| Output | Description |
|--------|-------------|
| `sns_topic_arn` | ARN of SNS topic for alarms |
| `main_alb_access_log_group` | CloudWatch log group for main ALB access logs |
| `services_alb_access_log_group` | CloudWatch log group for services ALB access logs |
| `lambda_function_arn` | ARN of log processing Lambda function |

## Rate Limiting

The module implements rate limiting for file operations:

### Main ALB Rate Limiting
- **Paths**: `/files/*`, `/directories/*`
- **Response**: HTTP 429 with JSON error message
- **Retry After**: 60 seconds

### Secondary ALB Rate Limiting
- **Paths**: `/files/*`, `/directories/*`, `/clients/v1/files/*`, `/clients/v1/directories/*`
- **Response**: HTTP 429 with JSON error message
- **Retry After**: 120 seconds

## Monitoring & Alerting

### CloudWatch Alarms

1. **4xx Error Alarm**
   - Metric: `HTTPCode_ELB_4XX_Count`
   - Threshold: > 50 errors in 10 minutes
   - Action: SNS notification

2. **5xx Error Alarm**
   - Metric: `HTTPCode_ELB_5XX_Count`
   - Threshold: > 10 errors in 10 minutes
   - Action: SNS notification

3. **Latency Alarm**
   - Metric: `TargetResponseTime`
   - Threshold: > 300 seconds (5 minutes)
   - Purpose: Monitor large file operations
   - Action: SNS notification

4. **Request Timeout Alarm**
   - Metric: `RequestCount`
   - Threshold: > 10 requests in 5 minutes
   - Action: SNS notification

5. **Rate Limit Alarm**
   - Metric: `HTTPCode_ELB_4XX_Count` (429 responses)
   - Threshold: > 20 rate limit responses
   - Action: SNS notification

### Log Processing

The Lambda function processes ALB logs from S3 and forwards them to CloudWatch:

- **Runtime**: Node.js 18.x
- **Memory**: 512 MB
- **Timeout**: 5 minutes
- **Triggers**: S3 ObjectCreated events
- **Purpose**: Parse and analyze ALB access/connection logs

## Security Features

- **SSL/TLS Termination**: All HTTPS traffic encrypted
- **HTTP Redirect**: Automatic HTTP to HTTPS redirect (301)
- **Security Groups**: Controlled access via security group rules
- **Rate Limiting**: Protection against excessive requests
- **Access Logging**: Full request audit trail
- **IAM Roles**: Least privilege access for Lambda functions

## Dependencies

- **VPC Module**: Provides network infrastructure
- **ACM Module**: Provides SSL/TLS certificates
- **Security Groups**: ALB-specific security group
- **S3 Bucket**: For access logs (if enabled)
- **Target Groups**: For ECS services or EC2 instances

## Health Checks

### Configuration Options
- **Path**: Configurable health check endpoint
- **Port**: Uses target group port
- **Protocol**: HTTP
- **Timeout**: 2-120 seconds (configurable)
- **Interval**: Must be > timeout (configurable)
- **Thresholds**: Configurable healthy/unhealthy counts

### Health Check Flow
```
ALB ──────────────▶ Target:8080/health
   ◀─────────────── HTTP 200 OK

Every 60s (configurable)
├── Timeout: 30s (configurable)
├── Healthy after: 2 consecutive successes
└── Unhealthy after: 3 consecutive failures
```

## Cost Considerations

- **ALB Hours**: Charged per ALB per hour
- **LCU (Load Balancer Capacity Units)**: Based on traffic patterns
- **Data Processing**: Charged per GB processed
- **CloudWatch Logs**: Storage and ingestion costs
- **Lambda Execution**: Log processing function costs
- **S3 Storage**: Access logs storage costs

## Best Practices

1. **Use HTTPS Only**: Always redirect HTTP to HTTPS
2. **Enable Logging**: Use access logs for troubleshooting
3. **Monitor Health Checks**: Set appropriate timeouts and thresholds
4. **Rate Limiting**: Enable for file operation endpoints
5. **Proper Naming**: Use consistent naming conventions
6. **Environment Separation**: Use different ALBs per environment
7. **Security Groups**: Restrict access to necessary ports only
8. **SSL Policies**: Use latest TLS security policies

## Troubleshooting

### ALB Not Accessible
1. Check security group rules
2. Verify subnet configuration
3. Confirm internet gateway attachment
4. Review Route53 DNS records

### Health Check Failures
1. Verify target application is running
2. Check health check path returns 200
3. Review security group rules for health check traffic
4. Adjust timeout and interval settings

### High Latency Alarms
1. Review target response times
2. Check for resource constraints
3. Analyze access logs for patterns
4. Consider scaling target capacity

### Rate Limiting Issues
1. Review rate limiting thresholds
2. Check application patterns
3. Adjust retry-after values
4. Monitor 429 response rates

## Integration with Other Modules

- **ECS**: Target group registration for ECS services
- **Route53**: DNS records pointing to ALB
- **CloudFront**: ALB as origin for CDN
- **WAF**: Web application firewall integration
- **API Gateway**: ALB as custom domain backend

## Maintenance

- **Monitor Metrics**: Review CloudWatch dashboards regularly
- **Update SSL Policies**: Keep TLS policies current
- **Log Rotation**: Manage CloudWatch log retention
- **Lambda Updates**: Keep log processor function updated
- **Capacity Planning**: Monitor LCU usage trends
- **Security Reviews**: Regular security group audits

## Support

For issues related to:
- **ALB Configuration**: Review Terraform configuration
- **Health Checks**: Verify target application health
- **Performance**: Analyze CloudWatch metrics and logs
- **SSL/TLS**: Check certificate configuration
- **Rate Limiting**: Review listener rules and thresholds