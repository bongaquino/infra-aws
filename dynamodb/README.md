# DynamoDB Configuration

This directory contains the Terraform configuration for setting up DynamoDB tables in AWS.

## Table Configuration

### Current Setup
- **Table Name**: `koneksi-staging-users`
- **Region**: `ap-southeast-1`
- **Billing Mode**: `PAY_PER_REQUEST`
- **Hash Key**: `id` (String type)
- **Security Features**:
  - Point-in-time recovery: Enabled
  - Server-side encryption: Enabled (using AWS KMS)
  - Deletion protection: Disabled (for staging)

### Table Schema
```json
{
    "id": "S",      // String - Hash Key
    "name": "S",    // String
    "email": "S"    // String
}
```

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

## Infrastructure as Code

### Directory Structure
```
dynamodb/
├── main.tf           # Main DynamoDB configuration
├── variables.tf      # Variable definitions
├── outputs.tf        # Output definitions
└── envs/
    ├── staging/      # Staging environment configuration
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── backend.tf
    │   └── terraform.tfvars
    ├── uat/          # UAT environment configuration
    └── prod/         # Production environment configuration
```

### Environment-Specific Configuration
Each environment (staging, UAT, prod) has its own configuration in the `envs` directory. The configuration includes:
- Environment-specific variables
- Backend configuration for state management
- Resource naming conventions

### Deployment
To deploy to a specific environment:
1. Navigate to the environment directory:
   ```bash
   cd envs/staging  # or uat/prod
   ```
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Plan the deployment:
   ```bash
   terraform plan
   ```
4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Security Considerations
1. The table uses AWS KMS for server-side encryption
2. Point-in-time recovery is enabled for data protection
3. Deletion protection is enabled in production
4. Access is controlled through IAM policies

## Monitoring and Maintenance
1. Monitor table metrics through CloudWatch
2. Set up alarms for:
   - Throttled requests
   - System errors
   - Consumed capacity
3. Regular backup verification
4. Performance optimization based on access patterns

## Best Practices
1. Use consistent naming conventions
2. Implement proper error handling
3. Use batch operations for multiple items
4. Implement retry logic for failed operations
5. Use appropriate read/write consistency levels
6. Monitor and optimize capacity usage 