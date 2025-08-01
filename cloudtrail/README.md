# AWS CloudTrail Module

This module provisions a comprehensive AWS CloudTrail infrastructure with advanced security monitoring, anomaly detection, and centralized audit logging for multi-environment AWS accounts. It provides enterprise-grade compliance, forensic capabilities, and real-time threat detection.

## Overview

The CloudTrail module creates a centralized audit logging system that captures all API activity across AWS environments with advanced security monitoring, automated threat detection, and comprehensive compliance reporting. It implements security best practices and provides real-time alerting for suspicious activities.

## Features

- **Multi-Region Coverage**: Captures events from all AWS regions globally
- **Organization-Wide Monitoring**: Single trail monitoring all environments (staging, UAT, prod)
- **Advanced Security Monitoring**: Real-time detection of security threats and anomalies
- **Comprehensive Audit Trail**: Complete API activity logging for compliance and forensics
- **Intelligent Threat Detection**: Machine learning-based anomaly detection for unusual patterns
- **Cost-Effective Storage**: S3 lifecycle policies with intelligent archiving
- **Real-Time Alerting**: Immediate notification of security events via SNS
- **Compliance Ready**: Meets SOC 2, PCI DSS, HIPAA, and other regulatory requirements
- **Data Event Logging**: S3 object-level and Lambda function invocation tracking
- **Encryption**: End-to-end encryption with AWS KMS support

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Multi-Environment AWS Account                        │
│                                                                                │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐           │
│  │   Staging Env    │    │    UAT Env      │    │    Prod Env     │           │
│  │                 │    │                 │    │                 │           │
│  │ • EC2/ECS      │    │ • EC2/ECS      │    │ • EC2/ECS      │           │
│  │ • RDS/Lambda   │    │ • RDS/Lambda   │    │ • RDS/Lambda   │           │
│  │ • S3/IAM       │    │ • S3/IAM       │    │ • S3/IAM       │           │
│  └─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘           │
│            │                      │                      │                   │
│            └──────────────────────┼──────────────────────┘                   │
│                                   │                                          │
│            ┌─────────────────────▼─────────────────────┐                     │
│            │        Centralized CloudTrail             │                     │
│            │                                           │                     │
│            │  ┌─────────────────────────────────────┐  │                     │
│            │  │           S3 Bucket                 │  │   ┌──────────────┐   │
│            │  │ • Encrypted Storage (KMS)           │──┼──▶│    KMS Key   │   │
│            │  │ • Versioning Enabled                │  │   │  Encryption  │   │
│            │  │ • Lifecycle Policies (90 days)     │  │   └──────────────┘   │
│            │  │ • Public Access Blocked             │  │                     │
│            │  └─────────────────────────────────────┘  │                     │
│            │                    │                      │                     │
│            │  ┌─────────────────▼───────────────────┐  │                     │
│            │  │        CloudWatch Logs             │  │                     │
│            │  │ • Real-time Log Streaming          │  │                     │
│            │  │ • 30-day Retention                 │  │                     │
│            │  │ • Metric Filters & Queries         │  │                     │
│            │  └─────────────────┬───────────────────┘  │                     │
│            │                    │                      │                     │
│            │  ┌─────────────────▼───────────────────┐  │   ┌──────────────┐   │
│            │  │      Security Monitoring           │──┼──▶│ SNS Topics   │   │
│            │  │ • Root User Activity Detection     │  │   │ Notifications│   │
│            │  │ • Unauthorized API Call Alerts     │  │   └──────────────┘   │
│            │  │ • Console Login without MFA        │  │                     │
│            │  │ • Anomaly Detection (ML)           │  │                     │
│            │  │ • High-Frequency API Monitoring    │  │                     │
│            │  └─────────────────────────────────────┘  │                     │
│            └───────────────────────────────────────────┘                     │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **API Calls**: All AWS service API calls across environments are captured
2. **CloudTrail**: Centralized trail processes and validates events
3. **S3 Storage**: Encrypted, versioned storage with lifecycle management
4. **CloudWatch Logs**: Real-time streaming for immediate analysis
5. **Security Monitoring**: Automated analysis and threat detection
6. **Alerting**: Instant notifications via SNS for security events

## Directory Structure

```
cloudtrail/
├── main.tf              # Main CloudTrail configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── README.md           # This documentation
└── envs/               # Environment-specific configurations (if needed)
```

## Resources Created

### Core CloudTrail Resources
- **aws_cloudtrail**: Main CloudTrail with multi-region support
- **aws_s3_bucket**: Encrypted log storage with versioning
- **aws_s3_bucket_policy**: Secure CloudTrail access permissions
- **aws_s3_bucket_lifecycle_configuration**: Cost optimization rules
- **aws_s3_bucket_public_access_block**: Security hardening

### Monitoring & Alerting
- **aws_cloudwatch_log_group**: Real-time log streaming
- **aws_cloudwatch_log_metric_filter**: Security pattern detection
- **aws_cloudwatch_metric_alarm**: Automated threat alerting
- **aws_iam_role**: CloudWatch logs access permissions

### Security Monitoring Patterns
- **Root User Activity Detection**: Alerts on any root user actions
- **Unauthorized API Call Monitoring**: Detects access denied events
- **Console Login without MFA**: Identifies weak authentication
- **High-Frequency API Detection**: Flags potential brute force attacks
- **Error Spike Monitoring**: Identifies system anomalies
- **Unusual Location Login Detection**: Geographic access patterns
- **Privileged Action Tracking**: IAM privilege escalation detection
- **Source IP Anomaly Detection**: Network-based threat identification

## Usage

### Basic CloudTrail Setup

```hcl
module "cloudtrail" {
  source = "./cloudtrail"

  # Basic configuration
  organization_name = "koneksi"
  
  # Security monitoring
  enable_security_monitoring = true
  enable_anomaly_detection   = true
  
  # CloudWatch integration
  enable_cloudwatch_logs         = true
  cloudwatch_logs_retention_days = 30
  
  # S3 storage settings
  s3_lifecycle_days           = 90
  s3_noncurrent_version_days  = 30
  
  # Optional SNS notifications
  alarm_sns_topic_arn = "arn:aws:sns:ap-southeast-1:123456789012:security-alerts"
  
  tags = {
    Project     = "Koneksi"
    Environment = "Multi-Environment"
    Owner       = "DevOps Team"
  }
}
```

### Production Setup with KMS Encryption

```hcl
module "cloudtrail" {
  source = "./cloudtrail"

  # Basic configuration
  organization_name = "koneksi"
  
  # Enhanced security
  enable_security_monitoring = true
  enable_anomaly_detection   = true
  kms_key_id                = "arn:aws:kms:ap-southeast-1:account:key/12345678-1234-1234-1234-123456789012"
  
  # Extended retention for compliance
  s3_lifecycle_days           = 2555  # 7 years
  s3_noncurrent_version_days  = 90
  cloudwatch_logs_retention_days = 90
  
  # Multi-region and global events
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  
  # Notifications
  alarm_sns_topic_arn = module.security_notifications.topic_arn
  sns_topic_arn      = module.security_notifications.topic_arn
  
  tags = {
    Project     = "Koneksi"
    Environment = "Production"
    Compliance  = "SOC2-PCI-DSS"
    Owner       = "Security Team"
  }
}
```

### Compliance-Focused Setup

```hcl
module "cloudtrail" {
  source = "./cloudtrail"

  # Organization settings
  organization_name = "koneksi"
  
  # Maximum security configuration
  enable_security_monitoring = true
  enable_anomaly_detection   = true
  enable_log_file_validation = true
  
  # Long-term retention for audits
  s3_lifecycle_days           = 3650  # 10 years
  s3_noncurrent_version_days  = 365   # 1 year
  cloudwatch_logs_retention_days = 365  # 1 year
  
  # Enhanced encryption
  kms_key_id = module.compliance_kms.key_arn
  
  # Complete coverage
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging               = true
  
  # Immediate alerting
  alarm_sns_topic_arn = module.compliance_alerts.topic_arn
  
  tags = {
    Project     = "Koneksi"
    Environment = "Compliance"
    Retention   = "10-years"
    Classification = "confidential"
  }
}
```

### Simple Deployment

1. **Navigate to module directory**:
```bash
cd koneksi-aws/cloudtrail
```

2. **Initialize Terraform**:
```bash
terraform init
```

3. **Plan the deployment**:
```bash
AWS_PROFILE=koneksi terraform plan
```

4. **Apply the configuration**:
```bash
AWS_PROFILE=koneksi terraform apply
```

5. **Verify CloudTrail is working**:
```bash
# Check trail status
aws cloudtrail describe-trails --trail-name-list koneksi-cloudtrail

# Check log group
aws logs describe-log-groups --log-group-name-prefix "/aws/cloudtrail/koneksi"

# Test security alarms
aws cloudwatch describe-alarms --alarm-names koneksi-root-usage
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `organization_name` | string | `koneksi` | Organization name for resource naming |

### CloudTrail Settings
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_logging` | bool | `true` | Enable logging for the CloudTrail |
| `is_multi_region_trail` | bool | `true` | Enable multi-region trail coverage |
| `include_global_service_events` | bool | `true` | Include global service events (IAM, Route53, etc.) |
| `enable_log_file_validation` | bool | `true` | Enable log file integrity validation |

### Storage & Retention
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `s3_lifecycle_days` | number | `90` | Days to retain logs in S3 before deletion |
| `s3_noncurrent_version_days` | number | `30` | Days to retain non-current object versions |
| `enable_cloudwatch_logs` | bool | `true` | Enable CloudWatch Logs integration |
| `cloudwatch_logs_retention_days` | number | `30` | CloudWatch logs retention period |

### Security & Monitoring
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_security_monitoring` | bool | `true` | Enable security monitoring with metric filters |
| `enable_anomaly_detection` | bool | `true` | Enable CloudWatch anomaly detection |
| `kms_key_id` | string | `null` | KMS key ID for CloudTrail encryption |

### Notifications
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `alarm_sns_topic_arn` | string | `null` | SNS topic ARN for CloudWatch alarms |
| `sns_topic_arn` | string | `null` | SNS topic ARN for CloudTrail notifications |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `cloudtrail_name` | Name of the CloudTrail |
| `cloudtrail_arn` | ARN of the CloudTrail |
| `cloudtrail_home_region` | Home region of the CloudTrail |
| `s3_bucket_name` | Name of the S3 bucket for CloudTrail logs |
| `s3_bucket_arn` | ARN of the S3 bucket for CloudTrail logs |
| `cloudwatch_log_group_name` | Name of the CloudWatch log group |
| `cloudwatch_log_group_arn` | ARN of the CloudWatch log group |
| `security_alarm_names` | List of security CloudWatch alarm names |
| `metric_filter_names` | List of CloudWatch log metric filter names |

## Security Monitoring

### Core Security Patterns

The module implements comprehensive security monitoring with real-time threat detection:

#### 1. Root User Activity Detection
- **Alarm Name**: `{organization}-root-usage`
- **Purpose**: Immediate alert on any root user activity
- **Pattern**: `{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }`
- **Threshold**: Any occurrence (threshold: 1)
- **Use Case**: Root account compromise detection

#### 2. Unauthorized API Call Monitoring
- **Alarm Name**: `{organization}-unauthorized-calls`
- **Purpose**: Detect potential privilege escalation attempts
- **Pattern**: `{ ($.errorCode = "*UnauthorizedOperation") || ($.errorCode = "AccessDenied*") }`
- **Threshold**: Any occurrence (threshold: 1)
- **Use Case**: Brute force API attacks, credential testing

#### 3. Console Login Without MFA
- **Alarm Name**: `{organization}-console-without-mfa`
- **Purpose**: Identify weak authentication practices
- **Pattern**: `{ ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") }`
- **Threshold**: Any occurrence (threshold: 1)
- **Use Case**: Policy compliance, security posture monitoring

### Advanced Threat Detection

#### 4. High-Frequency API Call Detection
- **Alarm Name**: `{organization}-high-frequency-api-calls`
- **Purpose**: Identify potential automated attacks or credential abuse
- **Threshold**: >100 API calls in 5 minutes
- **Use Case**: Brute force attacks, compromised service accounts

#### 5. Error Spike Monitoring
- **Alarm Name**: `{organization}-error-spike`
- **Purpose**: Detect system anomalies or attack patterns
- **Threshold**: >20 error events in 5 minutes
- **Use Case**: Service disruption, distributed attacks

#### 6. Unusual Geographic Login Detection
- **Alarm Name**: `{organization}-unusual-location-logins`
- **Purpose**: Identify potentially compromised credentials
- **Threshold**: >5 successful logins in 5 minutes
- **Use Case**: Account takeover, credential compromise

#### 7. Privileged Action Monitoring
- **Alarm Name**: `{organization}-privileged-actions`
- **Purpose**: Track potential privilege escalation
- **Threshold**: >3 privileged IAM actions in 5 minutes
- **Use Case**: Insider threats, compromised admin accounts

#### 8. Source IP Anomaly Detection
- **Alarm Name**: `{organization}-new-source-ip-spike`
- **Purpose**: Identify distributed attacks or compromised credentials
- **Threshold**: >50 requests from new IPs in 5 minutes
- **Use Case**: Distributed attacks, credential stuffing

### Security Monitoring Configuration

```hcl
# Enable all security monitoring
enable_security_monitoring = true
enable_anomaly_detection   = true

# Configure SNS for immediate alerts
alarm_sns_topic_arn = "arn:aws:sns:region:account:security-alerts"
```

### Custom Security Patterns

You can extend monitoring by adding custom CloudWatch Log metric filters:

```hcl
resource "aws_cloudwatch_log_metric_filter" "custom_security_pattern" {
  name           = "custom-security-monitoring"
  log_group_name = module.cloudtrail.cloudwatch_log_group_name
  pattern        = "{ $.eventName = \"CreateUser\" || $.eventName = \"DeleteUser\" }"

  metric_transformation {
    name      = "CustomSecurityEvents"
    namespace = "CloudTrail/SecurityMetrics"
    value     = "1"
  }
}
```

## Event Coverage

### Management Events (Always Captured)
- **IAM Operations**: User/role creation, policy changes, login events
- **EC2 Operations**: Instance creation/termination, security group changes
- **S3 Management**: Bucket creation/deletion, policy changes
- **RDS Operations**: Database creation/deletion, parameter changes
- **Lambda Operations**: Function creation/deletion, configuration changes
- **VPC Operations**: Network changes, security group modifications

### Data Events (Optional)
- **S3 Object Operations**: Object GET/PUT/DELETE operations
- **Lambda Invocations**: Function execution details
- **DynamoDB Operations**: Item-level read/write operations

### Global Service Events
- **Route 53**: DNS configuration changes
- **CloudFront**: Distribution modifications
- **IAM**: Cross-region identity operations
- **AWS Organizations**: Account management operations

## Compliance & Governance

### Regulatory Compliance
- **SOC 2**: Complete audit trail with integrity validation
- **PCI DSS**: Secure logging with encryption and access controls
- **HIPAA**: Comprehensive activity monitoring for healthcare data
- **GDPR**: Data access and modification tracking
- **ISO 27001**: Information security management compliance

### Audit Requirements
- **Log Integrity**: Digital signature validation enabled
- **Tamper Detection**: S3 bucket policy prevents unauthorized access
- **Retention Policies**: Configurable retention for compliance requirements
- **Access Control**: Least privilege access to log data
- **Encryption**: Data encrypted at rest and in transit

### Governance Features
```hcl
# Enable comprehensive compliance monitoring
enable_log_file_validation    = true
is_multi_region_trail         = true
include_global_service_events = true

# Set compliance retention periods
s3_lifecycle_days           = 2555  # 7 years for SOX
cloudwatch_logs_retention_days = 90   # 90 days for active monitoring
```

## Cost Management

### CloudTrail Pricing Components
- **Management Events**: $2.00 per 100,000 events (free tier: first 250,000 events/month)
- **Data Events**: $0.10 per 100,000 events for S3, $0.20 per 100,000 for Lambda
- **S3 Storage**: ~$0.023 per GB/month (Standard), transitions to cheaper classes
- **CloudWatch Logs**: $0.50 per GB ingested + $0.03 per GB stored
- **CloudWatch Alarms**: $0.10 per alarm per month

### Cost Optimization Strategies

#### 1. Selective Data Event Logging
```hcl
# Only monitor critical S3 buckets for data events
event_selector {
  read_write_type           = "All"
  include_management_events = true
  
  data_resource {
    type   = "AWS::S3::Object"
    values = ["arn:aws:s3:::critical-bucket/*"]
  }
}
```

#### 2. Intelligent Lifecycle Management
```hcl
s3_lifecycle_days           = 90    # Standard retention
s3_noncurrent_version_days  = 30    # Version cleanup

# Extended retention for compliance
s3_lifecycle_days = 2555  # 7 years for financial records
```

#### 3. Regional Optimization
- Deploy CloudTrail in your primary region to reduce cross-region costs
- Use regional S3 buckets to minimize data transfer charges

### Monthly Cost Examples
- **Small Environment**: ~$20-50/month (management events only)
- **Medium Environment**: ~$100-300/month (selective data events)
- **Large Environment**: ~$500-1500/month (comprehensive data events)

## Performance & Monitoring

### CloudWatch Insights Queries

#### Security Analysis
```sql
# Find all root user activities
fields @timestamp, userIdentity.type, eventName, sourceIPAddress
| filter userIdentity.type = "Root"
| sort @timestamp desc
| limit 100
```

#### Failed Login Analysis
```sql
# Analyze failed console logins
fields @timestamp, sourceIPAddress, errorMessage, userIdentity.userName
| filter eventName = "ConsoleLogin" and errorCode exists
| stats count() by sourceIPAddress
| sort count desc
```

#### API Call Frequency Analysis
```sql
# High-frequency API calls by IP
fields @timestamp, sourceIPAddress, eventName
| stats count() by sourceIPAddress, eventName
| sort count desc
| limit 50
```

### Performance Metrics Monitoring
```hcl
# Custom metric for CloudTrail processing delays
resource "aws_cloudwatch_metric_alarm" "cloudtrail_processing_delay" {
  alarm_name          = "cloudtrail-processing-delay"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DeliveryDelay"
  namespace           = "AWS/CloudTrail"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "300"  # 5 minutes
  alarm_description   = "CloudTrail log delivery delay"
}
```

## Log Analysis & Forensics

### Security Incident Response

#### 1. Rapid Threat Assessment
```bash
# Check for suspicious activity in last 24 hours
aws logs start-query \
  --log-group-name "/aws/cloudtrail/koneksi" \
  --start-time $(date -d '24 hours ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, sourceIPAddress, eventName, userIdentity.type | filter sourceIPAddress != "AWS Internal"'
```

#### 2. User Activity Timeline
```bash
# Track specific user activity
aws logs start-query \
  --log-group-name "/aws/cloudtrail/koneksi" \
  --start-time $(date -d '7 days ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, eventName, resources | filter userIdentity.userName = "suspicious-user"'
```

#### 3. Resource Access Patterns
```bash
# Find who accessed specific resources
aws logs start-query \
  --log-group-name "/aws/cloudtrail/koneksi" \
  --start-time $(date -d '30 days ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, userIdentity, eventName | filter resources[0].ARN like /specific-resource-arn/'
```

### Automated Threat Hunting

```python
# Example Lambda function for automated threat detection
import json
import boto3

def lambda_handler(event, context):
    logs_client = boto3.client('logs')
    
    # Query for suspicious patterns
    query = """
    fields @timestamp, sourceIPAddress, eventName, userIdentity.type
    | filter sourceIPAddress != "AWS Internal"
    | stats count() by sourceIPAddress
    | sort count desc
    | limit 10
    """
    
    response = logs_client.start_query(
        logGroupName='/aws/cloudtrail/koneksi',
        startTime=int((datetime.now() - timedelta(hours=1)).timestamp()),
        endTime=int(datetime.now().timestamp()),
        queryString=query
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }
```

## Troubleshooting

### Common Issues

#### CloudTrail Not Logging
```bash
# Check trail status
aws cloudtrail get-trail-status --name koneksi-cloudtrail

# Expected output should show:
# "IsLogging": true
# "LatestDeliveryTime": recent timestamp
```

**Solutions**:
1. Verify S3 bucket policy allows CloudTrail access
2. Check IAM permissions for CloudTrail service role
3. Ensure trail is enabled: `aws cloudtrail start-logging --name koneksi-cloudtrail`

#### S3 Bucket Permission Errors
```
Error: AccessDenied - CloudTrail cannot write to S3 bucket
```

**Solutions**:
1. Verify bucket policy includes CloudTrail service principal
2. Check bucket exists and is in the correct region
3. Ensure bucket name matches trail configuration

#### CloudWatch Logs Integration Issues
```
Error: Could not deliver logs to CloudWatch Logs
```

**Solutions**:
1. Verify IAM role has CloudWatch Logs permissions
2. Check log group exists and trail role can access it
3. Ensure log group ARN format is correct (includes `:*`)

#### High Costs
```
Unexpected CloudTrail charges
```

**Solutions**:
1. Review data event configuration - often the largest cost driver
2. Implement lifecycle policies for S3 storage
3. Use CloudWatch Logs retention to control storage costs
4. Monitor with AWS Cost Explorer and set billing alerts

### Debugging Commands

```bash
# Comprehensive CloudTrail status check
aws cloudtrail describe-trails --trail-name-list koneksi-cloudtrail
aws cloudtrail get-trail-status --name koneksi-cloudtrail
aws cloudtrail get-event-selectors --trail-name koneksi-cloudtrail

# Check S3 bucket configuration
aws s3api get-bucket-policy --bucket koneksi-cloudtrail-logs
aws s3api get-bucket-versioning --bucket koneksi-cloudtrail-logs
aws s3api get-bucket-encryption --bucket koneksi-cloudtrail-logs

# Verify CloudWatch Logs integration
aws logs describe-log-groups --log-group-name-prefix "/aws/cloudtrail/koneksi"
aws logs describe-metric-filters --log-group-name "/aws/cloudtrail/koneksi"

# Test security alarms
aws cloudwatch describe-alarms --alarm-name-prefix "koneksi-"
aws cloudwatch get-metric-statistics \
  --namespace "CloudTrail/SecurityMetrics" \
  --metric-name "koneksi-root-usage" \
  --start-time $(date -d '24 hours ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 3600 \
  --statistics Sum
```

## Best Practices

### Security
1. **Enable Log File Validation**: Ensures log integrity and detects tampering
2. **Use KMS Encryption**: Encrypt logs with customer-managed keys for enhanced security
3. **Restrict S3 Access**: Implement least privilege access to log bucket
4. **Multi-Region Trails**: Capture events from all regions for complete visibility
5. **Regular Log Analysis**: Implement automated log analysis and threat hunting

### Operational
1. **Monitor Trail Health**: Set up alarms for trail status and log delivery
2. **Cost Management**: Regularly review costs and optimize data event logging
3. **Retention Policies**: Align retention with compliance requirements
4. **Documentation**: Maintain documentation of security patterns and response procedures
5. **Testing**: Regularly test alarm notifications and incident response procedures

### Compliance
1. **Data Classification**: Tag resources appropriately for compliance tracking
2. **Access Controls**: Implement proper IAM policies for log access
3. **Audit Preparation**: Maintain readily accessible logs for compliance audits
4. **Change Management**: Document all changes to CloudTrail configuration
5. **Regular Reviews**: Conduct periodic reviews of security monitoring effectiveness

## Dependencies

- **S3**: Bucket for log storage with proper permissions
- **CloudWatch**: Log groups and metric filters for monitoring
- **IAM**: Service roles for CloudTrail and CloudWatch Logs access
- **KMS**: Optional encryption key for enhanced security
- **SNS**: Optional notification topics for security alerts

## Integration with Other Modules

- **S3**: Log storage with lifecycle management
- **IAM**: Access control and service roles
- **CloudWatch**: Monitoring, alerting, and log analysis
- **SNS**: Security alert notifications
- **KMS**: Log encryption and key management

## Maintenance

- **Regular Monitoring**: Review CloudWatch metrics and alarm status
- **Cost Optimization**: Analyze usage patterns and adjust configuration
- **Security Updates**: Update security patterns based on threat landscape
- **Compliance Reviews**: Ensure configuration meets regulatory requirements
- **Performance Tuning**: Optimize log delivery and analysis performance

## Support

For issues related to:
- **Configuration**: Review Terraform configuration and AWS CloudTrail documentation
- **Permissions**: Check IAM roles, policies, and resource permissions
- **Performance**: Analyze CloudWatch metrics and log delivery times
- **Costs**: Monitor usage patterns and optimize logging configuration
- **Security**: Review security patterns and incident response procedures 