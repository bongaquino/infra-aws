# DynamoDB Service Documentation

## Overview
DynamoDB is a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability. This document outlines the configuration and usage of DynamoDB in our infrastructure.

## Endpoints
### Staging Environment
```
Region: ap-southeast-1
Table Name: koneksi-staging-users
ARN: arn:aws:dynamodb:ap-southeast-1:985869370256:table/koneksi-staging-users
```

### UAT Environment
```
Region: ap-southeast-1
Table Name: koneksi-uat-users
ARN: arn:aws:dynamodb:ap-southeast-1:985869370256:table/koneksi-uat-users
```

### Production Environment
```
Region: ap-southeast-1
Table Name: koneksi-prod-users
ARN: arn:aws:dynamodb:ap-southeast-1:985869370256:table/koneksi-prod-users
```

### Connection Configuration
```javascript
// Node.js
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: 'ap-southeast-1',
    endpoint: 'https://dynamodb.ap-southeast-1.amazonaws.com'
});
```

```python
# Python
import boto3
dynamodb = boto3.resource('dynamodb',
    region_name='ap-southeast-1',
    endpoint_url='https://dynamodb.ap-southeast-1.amazonaws.com'
)
```

## Infrastructure Components

### DynamoDB Table
- **Name**: `koneksi-staging-users`
- **Region**: `ap-southeast-1`
- **Billing Mode**: `PAY_PER_REQUEST`
- **Primary Key**: `id` (String type)

### Security Features
- Server-side encryption using AWS KMS
- Point-in-time recovery enabled
- Deletion protection (enabled in production)

## Table Schema
```json
{
    "id": "S",      // String - Hash Key
    "name": "S",    // String
    "email": "S"    // String
}
```

## Access Methods

### AWS CLI
```bash
# Describe table
aws dynamodb describe-table --table-name koneksi-staging-users --region ap-southeast-1

# Put item
aws dynamodb put-item \
    --table-name koneksi-staging-users \
    --item '{
        "id": {"S": "user1"},
        "name": {"S": "Test User"},
        "email": {"S": "test@example.com"}
    }' \
    --region ap-southeast-1

# Get item
aws dynamodb get-item \
    --table-name koneksi-staging-users \
    --key '{"id": {"S": "user1"}}' \
    --region ap-southeast-1
```

### Node.js SDK
```javascript
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: 'ap-southeast-1'
});

// Example: Get item
async function getItem(id) {
    const params = {
        TableName: 'koneksi-staging-users',
        Key: { id }
    };
    return await dynamodb.get(params).promise();
}
```

### Python SDK
```python
import boto3
dynamodb = boto3.resource('dynamodb', region_name='ap-southeast-1')
table = dynamodb.Table('koneksi-staging-users')

# Example: Get item
def get_item(id):
    response = table.get_item(
        Key={'id': id}
    )
    return response
```

## Environment Support
The service is configured for multiple environments:
- Staging
- UAT
- Production

Each environment has its own:
- Table name (e.g., `koneksi-staging-users`, `koneksi-uat-users`, `koneksi-prod-users`)
- Security settings
- Backup configurations

## Security
- Server-side encryption using AWS KMS
- IAM policies for access control
- Point-in-time recovery for data protection
- Deletion protection in production

## Monitoring
- CloudWatch metrics for:
  - Consumed capacity
  - Throttled requests
  - System errors
- Alarms for:
  - High latency
  - Error rates
  - Capacity thresholds

## Best Practices
1. Use batch operations for multiple items
2. Implement retry logic for failed operations
3. Monitor and optimize capacity usage
4. Use appropriate read/write consistency levels
5. Implement proper error handling
6. Follow AWS security best practices 