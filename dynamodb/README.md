# AWS DynamoDB Module

This module provisions production-ready Amazon DynamoDB tables with comprehensive features including auto-scaling, point-in-time recovery, encryption, monitoring, and VPC endpoint support. It provides flexible configuration options for various use cases from simple key-value storage to complex multi-index applications.

## Overview

The DynamoDB module creates highly scalable, fully managed NoSQL databases with enterprise-grade security, performance optimization, and operational monitoring. It supports both on-demand and provisioned billing modes, automatic scaling, global secondary indexes, and comprehensive backup strategies.

## Features

- **Multiple Billing Modes**: Pay-per-request and provisioned capacity with auto-scaling
- **High Availability**: Multi-AZ deployment with automatic failover
- **Security & Encryption**: Server-side encryption with AWS KMS integration
- **Backup & Recovery**: Point-in-time recovery and automated backups
- **Performance Optimization**: Auto-scaling policies and capacity management
- **Monitoring & Alerting**: CloudWatch integration with custom alarms
- **Network Security**: VPC endpoint support for private access
- **Global Secondary Indexes**: Support for complex query patterns
- **DynamoDB Streams**: Real-time data change capture
- **Lifecycle Management**: Automated deletion protection and policies

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Application Layer                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Node.js App   │  │   Python App    │  │      Go/Java Apps           │ │
│  │   (SDK v3)      │  │    (Boto3)      │  │      (AWS SDK)              │ │
│  └─────────┬───────┘  └─────────┬───────┘  └─────────────┬───────────────┘ │
└───────────┼────────────────────┼────────────────────────┼─────────────────┘
            │                    │                        │                  
            └────────────────────┼────────────────────────┘                  
                                 │                                           
┌─────────────────────────────────▼─────────────────────────────────────────┐ 
│                         VPC Endpoint (Optional)                          │ 
│  • Private network access     • Enhanced security                        │ 
│  • No internet gateway        • Reduced data transfer costs              │ 
└─────────────────────────────────┬─────────────────────────────────────────┘ 
                                  │                                           
┌─────────────────────────────────▼─────────────────────────────────────────┐ 
│                            DynamoDB Table                                 │ 
│                                                                           │ 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐│ 
│  │  Primary Index  │  │ Global Secondary│  │      Auto-Scaling           ││ 
│  │  (Hash + Range) │  │     Indexes     │  │   (Read/Write Capacity)     ││ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘│ 
│                                                                           │ 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐│ 
│  │   Encryption    │  │   Point-in-Time │  │      DynamoDB Streams       ││ 
│  │   (AWS KMS)     │  │     Recovery    │  │   (Change Data Capture)     ││ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘│ 
└─────────────────────────────────┬─────────────────────────────────────────┘ 
                                  │                                           
┌─────────────────────────────────▼─────────────────────────────────────────┐ 
│                          Monitoring & Alerting                           │ 
│                                                                           │ 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐│ 
│  │   CloudWatch    │  │    Custom       │  │      Performance            ││ 
│  │    Metrics      │  │    Alarms       │  │      Dashboard              ││ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘│ 
└───────────────────────────────────────────────────────────────────────────┘ 
```

## Directory Structure

```
dynamodb/
├── README.md                    # This documentation
├── main.tf                      # Core DynamoDB resources
├── variables.tf                 # Input variables
├── outputs.tf                   # Module outputs
├── backend.tf                   # Backend configuration
├── terraform.tfvars             # Default variable values
└── envs/                        # Environment-specific configurations
    ├── staging/
    │   ├── main.tf             # Staging environment setup
    │   ├── variables.tf        # Staging variables
    │   ├── outputs.tf          # Staging outputs
    │   ├── backend.tf          # Staging backend
    │   └── terraform.tfvars    # Staging values
    ├── uat/
    │   ├── main.tf             # UAT environment setup
    │   ├── variables.tf        # UAT variables
    │   ├── outputs.tf          # UAT outputs
    │   ├── backend.tf          # UAT backend
    │   └── terraform.tfvars    # UAT values
    └── prod/
        ├── main.tf             # Production environment setup
        ├── variables.tf        # Production variables
        ├── outputs.tf          # Production outputs
        ├── backend.tf          # Production backend
        └── terraform.tfvars    # Production values
```

## Resources Created

### Core DynamoDB Resources
- **aws_dynamodb_table**: Main table with configurable schema and indexes
- **aws_dynamodb_table_item**: Optional pre-populated items
- **aws_dynamodb_global_table**: Global replication (if configured)

### Auto-Scaling Resources
- **aws_appautoscaling_target**: Read and write capacity targets
- **aws_appautoscaling_policy**: Target tracking scaling policies

### Network Security
- **aws_vpc_endpoint**: Private network access to DynamoDB
- **aws_vpc_endpoint_route_table_association**: Route table associations

### Monitoring & Alerting
- **aws_cloudwatch_metric_alarm**: Read/write throttling alarms
- **aws_cloudwatch_dashboard**: Performance monitoring dashboard

## Accessing the Table

### AWS CLI Commands

1. **Describe Table**
```bash
aws dynamodb describe-table --table-name koneksi-staging-users --region ap-southeast-1
```

2. **Put Item**
```bash
aws dynamodb put-item \
    --table-name koneksi-staging-users \
    --item '{
        "id": {"S": "user1"},
        "name": {"S": "Test User"},
        "email": {"S": "test@example.com"}
    }' \
    --region ap-southeast-1
```

3. **Get Item**
```bash
aws dynamodb get-item \
    --table-name koneksi-staging-users \
    --key '{"id": {"S": "user1"}}' \
    --region ap-southeast-1
```

4. **Update Item**
```bash
aws dynamodb update-item \
    --table-name koneksi-staging-users \
    --key '{"id": {"S": "user1"}}' \
    --update-expression "SET #n = :name" \
    --expression-attribute-names '{"#n": "name"}' \
    --expression-attribute-values '{":name": {"S": "Updated Name"}}' \
    --region ap-southeast-1
```

5. **Delete Item**
```bash
aws dynamodb delete-item \
    --table-name koneksi-staging-users \
    --key '{"id": {"S": "user1"}}' \
    --region ap-southeast-1
```

### Node.js Example
```javascript
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: 'ap-southeast-1'
});

// Put Item
async function putItem() {
    const params = {
        TableName: 'koneksi-staging-users',
        Item: {
            id: 'user1',
            name: 'Test User',
            email: 'test@example.com'
        }
    };
    return await dynamodb.put(params).promise();
}

// Get Item
async function getItem(id) {
    const params = {
        TableName: 'koneksi-staging-users',
        Key: { id }
    };
    return await dynamodb.get(params).promise();
}

// Update Item
async function updateItem(id, updates) {
    const params = {
        TableName: 'koneksi-staging-users',
        Key: { id },
        UpdateExpression: 'SET #n = :name, email = :email',
        ExpressionAttributeNames: {
            '#n': 'name'
        },
        ExpressionAttributeValues: {
            ':name': updates.name,
            ':email': updates.email
        }
    };
    return await dynamodb.update(params).promise();
}

// Delete Item
async function deleteItem(id) {
    const params = {
        TableName: 'koneksi-staging-users',
        Key: { id }
    };
    return await dynamodb.delete(params).promise();
}
```

### Python Example
```python
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb', region_name='ap-southeast-1')
table = dynamodb.Table('koneksi-staging-users')

# Put Item
def put_item():
    response = table.put_item(
        Item={
            'id': 'user1',
            'name': 'Test User',
            'email': 'test@example.com'
        }
    )
    return response

# Get Item
def get_item(id):
    response = table.get_item(
        Key={
            'id': id
        }
    )
    return response

# Update Item
def update_item(id, updates):
    response = table.update_item(
        Key={
            'id': id
        },
        UpdateExpression='SET #n = :name, email = :email',
        ExpressionAttributeNames={
            '#n': 'name'
        },
        ExpressionAttributeValues={
            ':name': updates['name'],
            ':email': updates['email']
        }
    )
    return response

# Delete Item
def delete_item(id):
    response = table.delete_item(
        Key={
            'id': id
        }
    )
    return response
```

## Usage

### Basic DynamoDB Table Setup

```hcl
module "dynamodb_table" {
  source = "./dynamodb"

  # Basic configuration
  table_name    = "koneksi-staging-users"
  hash_key      = "id"
  range_key     = null  # Single key table
  billing_mode  = "PAY_PER_REQUEST"

  # Security
  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true

  # Environment
  project     = "koneksi"
  environment = "staging"
  aws_region  = "ap-southeast-1"

  tags = {
    Environment = "staging"
    Project     = "koneksi"
  }
}
```

### Provisioned Capacity with Auto-Scaling

```hcl
module "dynamodb_table" {
  source = "./dynamodb"

  # Table configuration
  table_name   = "koneksi-prod-users"
  hash_key     = "id"
  range_key    = "created_at"
  billing_mode = "PROVISIONED"

  # Capacity configuration
  min_read_capacity                = 5
  max_read_capacity                = 100
  min_write_capacity               = 5
  max_write_capacity               = 100
  target_read_capacity_utilization = 70
  target_write_capacity_utilization = 70

  # High availability
  point_in_time_recovery_enabled = true
  stream_enabled                = true

  # Environment
  project     = "koneksi"
  environment = "production"
  aws_region  = "ap-southeast-1"
}
```

### With Global Secondary Indexes

```hcl
module "dynamodb_table" {
  source = "./dynamodb"

  table_name   = "koneksi-uat-orders"
  hash_key     = "order_id"
  range_key    = "created_at"
  billing_mode = "PAY_PER_REQUEST"

  # Global Secondary Indexes
  global_secondary_indexes = [
    {
      name               = "UserIndex"
      hash_key           = "user_id"
      range_key          = "created_at"
      projection_type    = "ALL"
      read_capacity      = 5
      write_capacity     = 5
    },
    {
      name               = "StatusIndex"
      hash_key           = "status"
      range_key          = "updated_at"
      projection_type    = "KEYS_ONLY"
      read_capacity      = 5
      write_capacity     = 5
    }
  ]

  project     = "koneksi"
  environment = "uat"
}
```

### VPC Endpoint Configuration

```hcl
module "dynamodb_table" {
  source = "./dynamodb"

  table_name = "koneksi-private-table"
  hash_key   = "id"

  # VPC Endpoint for private access
  vpc_id                        = module.vpc.vpc_id
  data_private_route_table_ids  = module.vpc.private_route_table_ids

  project     = "koneksi"
  environment = "production"
}
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `table_name` | string | - | Name of the DynamoDB table |
| `hash_key` | string | `"id"` | Hash key (partition key) for the table |
| `range_key` | string | `null` | Range key (sort key) for the table |
| `project` | string | - | Project name for resource naming |
| `environment` | string | - | Environment name (staging/uat/prod) |
| `aws_region` | string | `"ap-southeast-1"` | AWS region for resources |

### Billing & Capacity
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `billing_mode` | string | `"PAY_PER_REQUEST"` | Billing mode (PAY_PER_REQUEST or PROVISIONED) |
| `min_read_capacity` | number | `5` | Minimum read capacity units (PROVISIONED mode) |
| `max_read_capacity` | number | `100` | Maximum read capacity units (PROVISIONED mode) |
| `min_write_capacity` | number | `5` | Minimum write capacity units (PROVISIONED mode) |
| `max_write_capacity` | number | `100` | Maximum write capacity units (PROVISIONED mode) |
| `target_read_capacity_utilization` | number | `70` | Target read capacity utilization percentage |
| `target_write_capacity_utilization` | number | `70` | Target write capacity utilization percentage |

### Features & Security
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `point_in_time_recovery_enabled` | bool | `true` | Enable point-in-time recovery |
| `server_side_encryption_enabled` | bool | `true` | Enable server-side encryption |
| `stream_enabled` | bool | `false` | Enable DynamoDB Streams |
| `stream_view_type` | string | `"NEW_AND_OLD_IMAGES"` | Stream view type when enabled |

### Global Secondary Indexes
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `global_secondary_indexes` | list(object) | `[]` | List of global secondary index configurations |

#### GSI Object Structure
```hcl
{
  name               = string  # Index name
  hash_key           = string  # GSI hash key
  range_key          = string  # GSI range key (optional)
  projection_type    = string  # ALL, KEYS_ONLY, or INCLUDE
  read_capacity      = number  # Read capacity (PROVISIONED mode)
  write_capacity     = number  # Write capacity (PROVISIONED mode)
}
```

### Network Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_id` | string | `null` | VPC ID for VPC endpoint creation |
| `data_private_route_table_ids` | list(string) | `[]` | Route table IDs for VPC endpoint |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `table_name` | Name of the DynamoDB table |
| `table_arn` | ARN of the DynamoDB table |
| `table_id` | ID of the DynamoDB table |
| `table_stream_arn` | ARN of the DynamoDB table stream (if enabled) |
| `table_stream_label` | Timestamp of the DynamoDB table stream (if enabled) |
| `vpc_endpoint_id` | ID of the VPC endpoint (if created) |
| `vpc_endpoint_dns_entry` | DNS entry for the VPC endpoint (if created) |
| `read_capacity_alarm_arn` | ARN of the read throttling alarm |
| `write_capacity_alarm_arn` | ARN of the write throttling alarm |

## Environment-Specific Deployment

### Staging Environment
   ```bash
cd koneksi-aws/dynamodb/envs/staging
terraform init
AWS_PROFILE=koneksi terraform plan
AWS_PROFILE=koneksi terraform apply
   ```

### UAT Environment
   ```bash
cd koneksi-aws/dynamodb/envs/uat
   terraform init
AWS_PROFILE=koneksi terraform plan
AWS_PROFILE=koneksi terraform apply
   ```

### Production Environment
   ```bash
cd koneksi-aws/dynamodb/envs/prod
terraform init
AWS_PROFILE=koneksi terraform plan
AWS_PROFILE=koneksi terraform apply
```

## Performance Optimization

### Capacity Planning

#### Pay-Per-Request vs Provisioned
- **Pay-Per-Request**: Ideal for unpredictable workloads, automatic scaling
- **Provisioned**: Cost-effective for predictable workloads, manual capacity management

```hcl
# Pay-per-request for variable workloads
billing_mode = "PAY_PER_REQUEST"

# Provisioned for predictable traffic
billing_mode = "PROVISIONED"
min_read_capacity = 5
max_read_capacity = 100
target_read_capacity_utilization = 70
```

### Global Secondary Indexes (GSI) Optimization

```hcl
# Efficient GSI design
global_secondary_indexes = [
  {
    name               = "UserEmailIndex"
    hash_key           = "email"
    range_key          = null
    projection_type    = "KEYS_ONLY"  # Minimize storage costs
    read_capacity      = 5
    write_capacity     = 5
  }
]
```

#### GSI Best Practices
1. **Sparse Indexes**: Only items with the GSI key are included
2. **Projection Types**:
   - `KEYS_ONLY`: Smallest storage, lowest cost
   - `INCLUDE`: Include specific attributes
   - `ALL`: All attributes, highest cost
3. **Avoid Hot Partitions**: Distribute GSI keys evenly

### Query Optimization

#### Efficient Query Patterns
```python
# Good: Use hash key + range key
response = table.query(
    KeyConditionExpression=Key('user_id').eq('123') & 
                          Key('created_at').between('2023-01-01', '2023-12-31')
)

# Avoid: Full table scans
response = table.scan()  # Expensive operation
```

#### Batch Operations
```python
# Batch write for multiple items
with table.batch_writer() as batch:
    for item in items:
        batch.put_item(Item=item)

# Batch get for multiple items
response = dynamodb.batch_get_item(
    RequestItems={
        'table_name': {
            'Keys': [{'id': '1'}, {'id': '2'}, {'id': '3'}]
        }
    }
)
```

## Security Features

### Encryption & Data Protection
- **Server-Side Encryption**: AES-256 encryption at rest
- **Encryption in Transit**: TLS 1.2 for all communications
- **Point-in-Time Recovery**: Restore to any point within 35 days
- **Continuous Backups**: Automatic backup without performance impact

### Access Control
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:region:account:table/koneksi-staging-users",
        "arn:aws:dynamodb:region:account:table/koneksi-staging-users/index/*"
      ],
      "Condition": {
        "ForAllValues:StringEquals": {
          "dynamodb:LeadingKeys": ["${aws:userid}"]
        }
      }
    }
  ]
}
```

### VPC Endpoint Security
```hcl
# Private network access
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/koneksi-*"
      }
    ]
  })
}
```

## Monitoring & Alerting

### CloudWatch Metrics
```hcl
# Read throttling alarm
resource "aws_cloudwatch_metric_alarm" "read_throttled_events" {
  alarm_name          = "dynamodb-read-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DynamoDB read throttling detected"

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Capacity utilization monitoring
resource "aws_cloudwatch_metric_alarm" "high_read_capacity" {
  alarm_name          = "dynamodb-high-read-capacity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "80"
  alarm_description   = "DynamoDB high read capacity utilization"

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }
}
```

### Custom Dashboards
```hcl
resource "aws_cloudwatch_dashboard" "dynamodb" {
  dashboard_name = "DynamoDB-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.main.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "ThrottledRequests", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Capacity Metrics"
        }
      }
    ]
  })
}
```

## Cost Management

### Billing Mode Comparison
| Aspect | Pay-Per-Request | Provisioned |
|--------|----------------|-------------|
| **Use Case** | Variable/unpredictable workloads | Steady, predictable traffic |
| **Pricing** | Per request | Per hour for provisioned capacity |
| **Scaling** | Automatic | Manual or auto-scaling |
| **Cost** | Higher per request | Lower for consistent usage |

### Cost Optimization Strategies

#### 1. Choose Appropriate Billing Mode
```hcl
# For development/testing
billing_mode = "PAY_PER_REQUEST"

# For production with predictable load
billing_mode = "PROVISIONED"
min_read_capacity = 10
max_read_capacity = 100
```

#### 2. Optimize Global Secondary Indexes
```hcl
# Minimize GSI storage costs
global_secondary_indexes = [
  {
    name               = "StatusIndex"
    hash_key           = "status"
    projection_type    = "KEYS_ONLY"  # Only store keys
    read_capacity      = 5
    write_capacity     = 5
  }
]
```

#### 3. Use DynamoDB Streams Efficiently
```hcl
# Enable streams only when needed
stream_enabled   = true
stream_view_type = "KEYS_ONLY"  # Minimal stream data
```

### Cost Monitoring
   ```bash
# Monitor costs with AWS CLI
aws ce get-cost-and-usage \
  --time-period Start=2023-01-01,End=2023-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://dynamodb-filter.json
```

## Troubleshooting

### Common Issues

#### Read/Write Throttling
**Symptoms**: `ProvisionedThroughputExceededException` errors
**Solutions**:
1. Enable auto-scaling for provisioned tables
2. Increase provisioned capacity
3. Switch to pay-per-request billing
4. Optimize query patterns to avoid hot partitions

#### Hot Partitions
**Symptoms**: Uneven capacity utilization, throttling on specific keys
**Solutions**:
1. Use composite keys to distribute load
2. Add random suffix to partition keys
3. Pre-warm table by gradually increasing traffic

#### High Costs
**Symptoms**: Unexpected DynamoDB charges
**Solutions**:
1. Analyze access patterns and optimize GSIs
2. Switch billing modes based on usage
3. Use DynamoDB On-Demand for variable workloads
4. Monitor and optimize projection types

### Debugging Commands

```bash
# Check table status
aws dynamodb describe-table --table-name koneksi-staging-users

# Monitor table metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=koneksi-staging-users \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Check for throttling
aws dynamodb describe-table --table-name koneksi-staging-users \
  --query 'Table.BillingModeSummary'

# Validate table schema
aws dynamodb describe-table --table-name koneksi-staging-users \
  --query 'Table.{HashKey:KeySchema[0],RangeKey:KeySchema[1],GSI:GlobalSecondaryIndexes[*].{Name:IndexName,Keys:KeySchema}}'
```

## Best Practices

### Schema Design
1. **Single Table Design**: Use one table for related entities when possible
2. **Composite Keys**: Combine multiple attributes for efficient queries
3. **Hierarchical Data**: Use sort keys to model relationships
4. **Sparse Indexes**: Use GSIs for attributes that exist in some items

### Application Patterns
1. **Exponential Backoff**: Implement retry logic with exponential backoff
2. **Connection Pooling**: Reuse connections to reduce latency
3. **Batch Operations**: Use batch operations for multiple items
4. **Consistent Reads**: Use eventually consistent reads when possible

### Operational
1. **Monitor Continuously**: Set up comprehensive CloudWatch alarms
2. **Backup Strategy**: Enable point-in-time recovery for critical tables
3. **Access Patterns**: Design schema based on query patterns
4. **Cost Optimization**: Regular review of capacity and billing modes

### Security
1. **Least Privilege**: Grant minimum required permissions
2. **Encryption**: Enable encryption at rest and in transit
3. **VPC Endpoints**: Use VPC endpoints for private access
4. **Audit Logging**: Enable CloudTrail for API call logging

## Dependencies

- **IAM**: Service roles and policies for DynamoDB access
- **CloudWatch**: Monitoring, logging, and alerting
- **VPC**: Optional VPC endpoint for private network access
- **Application Auto Scaling**: Automatic capacity scaling
- **AWS KMS**: Encryption key management
- **SNS**: Alarm notifications

## Integration with Other Modules

- **VPC**: Private network access via VPC endpoints
- **IAM**: Access control and service roles
- **CloudWatch**: Monitoring and alerting integration
- **Lambda**: Event-driven processing with DynamoDB Streams
- **API Gateway**: REST API integration with DynamoDB
- **CloudTrail**: Audit logging for DynamoDB operations

## Maintenance

- **Capacity Review**: Monthly review of capacity utilization
- **Cost Optimization**: Quarterly cost analysis and optimization
- **Performance Tuning**: Regular query pattern analysis
- **Security Audits**: Annual security configuration review
- **Backup Testing**: Quarterly point-in-time recovery testing

## Support

For issues related to:
- **Configuration**: Review Terraform configuration and DynamoDB documentation
- **Performance**: Analyze CloudWatch metrics and query patterns
- **Costs**: Monitor usage patterns and optimize billing configuration
- **Security**: Review IAM policies and access patterns
- **Throttling**: Analyze capacity utilization and scaling policies 