# AWS Systems Manager Parameter Store Module

This module manages configuration parameters and secrets using AWS Systems Manager Parameter Store for the Koneksi infrastructure, providing secure, scalable, and centralized configuration management.

## Overview

The Parameter Store module creates and manages both standard and secure parameters with automatic environment-based naming conventions. It supports encryption for sensitive data and provides a centralized approach to configuration management across all environments.

## Features

- **Standard Parameters**: Plain text configuration values
- **Secure Parameters**: Encrypted secrets using AWS KMS
- **Environment Isolation**: Automatic environment-based parameter naming
- **Centralized Management**: Single source of truth for configuration
- **Version Control**: Parameter versioning and history
- **IAM Integration**: Fine-grained access control
- **Cost Effective**: No additional charges for standard parameters
- **API Access**: Programmatic access via AWS SDK/CLI
- **Terraform Integration**: Full infrastructure-as-code management

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Parameter     │    │      KMS        │
│   (ECS/Lambda)  │───▶│     Store       │───▶│   (Encryption)  │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       ▼
         │              ┌─────────────────┐
         │              │   Standard      │
         │              │  Parameters     │
         │              │  (Plain Text)   │
         │              └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   IAM Roles &   │    │     Secure      │
│   Policies      │    │   Parameters    │
│ (Access Control)│    │   (Encrypted)   │
└─────────────────┘    └─────────────────┘
```

## Directory Structure

```
parameter_store/
├── main.tf              # Main Parameter Store configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── staging.tfvars       # Staging-specific values
├── prod.tfvars          # Production-specific values
├── envs/                # Environment-specific configurations
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── uat/
│   └── prod/
└── README.md           # This documentation
```

## Resources Created

### Parameter Store Resources
- **aws_ssm_parameter (parameters)**: Standard parameters for configuration
- **aws_ssm_parameter (secure_parameters)**: Encrypted parameters for secrets

## Naming Convention

All parameters follow a consistent naming pattern:
```
/koneksi/{environment}/{parameter_name}
```

Examples:
- `/koneksi/staging/database-host`
- `/koneksi/staging/jwt-secret`
- `/koneksi/prod/api-url`
- `/koneksi/prod/database-password`

## Usage

### Basic Configuration

```hcl
module "parameter_store" {
  source = "./parameter_store"
  
  environment = "staging"
  
  # Standard parameters (plain text)
  parameters = {
    "database-host" = "staging-db.koneksi.internal"
    "api-url"       = "https://api-staging.koneksi.co.kr"
    "app-version"   = "1.2.3"
    "debug-mode"    = "true"
  }
  
  # Secure parameters (encrypted)
  secure_parameters = {
    "database-password" = "super-secret-password"
    "jwt-secret"        = "jwt-signing-secret-key"
    "api-key"          = "external-api-key-value"
    "github-token"     = "your_github_token_here"
  }
}
```

### Environment-Specific Deployment

1. **Navigate to Parameter Store directory**:
```bash
cd koneksi-aws/parameter_store
```

2. **Deploy to specific environment**:
```bash
cd envs/staging
terraform init
AWS_PROFILE=koneksi terraform plan
AWS_PROFILE=koneksi terraform apply
```

3. **Using workspace-based deployment**:
```bash
# Main directory approach
terraform workspace select staging
AWS_PROFILE=koneksi terraform plan -var-file=staging.tfvars
AWS_PROFILE=koneksi terraform apply -var-file=staging.tfvars
```

## Input Variables

### Core Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | string | `""` | Environment name (uses workspace if empty) |
| `parameters` | map(string) | `{}` | Map of standard parameter names to values |
| `secure_parameters` | map(string) | `{}` | Map of secure parameter names to values |

## Outputs

| Output | Description |
|--------|-------------|
| `environment` | Current environment name |
| `parameter_arns` | ARNs of all standard parameters |
| `secure_parameter_arns` | ARNs of all secure parameters (sensitive) |
| `parameter_names` | Names of all standard parameters |
| `secure_parameter_names` | Names of all secure parameters (sensitive) |

## Parameter Types

### Standard Parameters
- **Type**: String
- **Encryption**: None
- **Use Case**: Non-sensitive configuration
- **Cost**: Free (up to 10,000 parameters)
- **Access**: Plain text retrieval

**Examples**:
```hcl
parameters = {
  "app-name"        = "koneksi-backend"
  "app-version"     = "2.1.0"
  "database-host"   = "prod-database.koneksi.internal"
  "database-port"   = "5432"
  "redis-host"      = "prod-redis.cache.amazonaws.com"
  "log-level"       = "info"
  "max-connections" = "100"
  "timeout"         = "30"
}
```

### Secure Parameters
- **Type**: SecureString
- **Encryption**: AWS KMS
- **Use Case**: Sensitive data and secrets
- **Cost**: $0.05 per 10,000 API calls
- **Access**: Decrypted on retrieval (with proper IAM permissions)

**Examples**:
```hcl
secure_parameters = {
  "database-password"    = var.database_password
  "database-username"    = var.database_username
  "jwt-secret"          = var.jwt_secret
  "encryption-key"      = var.encryption_key
  "third-party-api-key" = var.third_party_api_key
  "oauth-client-secret" = var.oauth_client_secret
  "webhook-secret"      = var.webhook_secret
}
```

## Application Integration

### Environment Variables in ECS
```hcl
# In ECS task definition
container_secrets = [
  {
    name      = "DATABASE_PASSWORD"
    valueFrom = "/koneksi/staging/database-password"
  },
  {
    name      = "JWT_SECRET"
    valueFrom = "/koneksi/staging/jwt-secret"
  }
]

container_environment = [
  {
    name  = "DATABASE_HOST"
    value = "/koneksi/staging/database-host"
  },
  {
    name  = "API_URL"
    value = "/koneksi/staging/api-url"
  }
]
```

### CodeBuild Integration
```yaml
# In buildspec.yml
phases:
  pre_build:
    commands:
      - GITHUB_TOKEN=$(aws ssm get-parameter --name "/koneksi/staging/github-token" --with-decryption --query 'Parameter.Value' --output text)
      - DATABASE_URL=$(aws ssm get-parameter --name "/koneksi/staging/database-url" --with-decryption --query 'Parameter.Value' --output text)
```

### Application Code Examples

#### Python (boto3)
```python
import boto3

ssm = boto3.client('ssm', region_name='ap-southeast-1')

# Get standard parameter
response = ssm.get_parameter(Name='/koneksi/staging/database-host')
database_host = response['Parameter']['Value']

# Get secure parameter
response = ssm.get_parameter(
    Name='/koneksi/staging/database-password',
    WithDecryption=True
)
database_password = response['Parameter']['Value']

# Get multiple parameters
response = ssm.get_parameters(
    Names=[
        '/koneksi/staging/database-host',
        '/koneksi/staging/database-password'
    ],
    WithDecryption=True
)
parameters = {param['Name']: param['Value'] for param in response['Parameters']}
```

#### Node.js (AWS SDK)
```javascript
const AWS = require('aws-sdk');
const ssm = new AWS.SSM({ region: 'ap-southeast-1' });

// Get standard parameter
const getParameter = async (name) => {
  const result = await ssm.getParameter({ Name: name }).promise();
  return result.Parameter.Value;
};

// Get secure parameter
const getSecureParameter = async (name) => {
  const result = await ssm.getParameter({ 
    Name: name, 
    WithDecryption: true 
  }).promise();
  return result.Parameter.Value;
};

// Usage
const databaseHost = await getParameter('/koneksi/staging/database-host');
const databasePassword = await getSecureParameter('/koneksi/staging/database-password');
```

#### Go (AWS SDK)
```go
package main

import (
    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/ssm"
)

func getParameter(svc *ssm.SSM, name string, secure bool) (string, error) {
    input := &ssm.GetParameterInput{
        Name:           aws.String(name),
        WithDecryption: aws.Bool(secure),
    }
    
    result, err := svc.GetParameter(input)
    if err != nil {
        return "", err
    }
    
    return *result.Parameter.Value, nil
}

// Usage
sess := session.Must(session.NewSession(&aws.Config{
    Region: aws.String("ap-southeast-1"),
}))
svc := ssm.New(sess)

databaseHost, _ := getParameter(svc, "/koneksi/staging/database-host", false)
databasePassword, _ := getParameter(svc, "/koneksi/staging/database-password", true)
```

## Environment-Specific Examples

### Staging Environment
```hcl
# envs/staging/terraform.tfvars
environment = "staging"

parameters = {
  "database-host"     = "staging-postgres.koneksi.internal"
  "redis-host"        = "staging-redis.cache.amazonaws.com"
  "api-url"          = "https://api-staging.koneksi.co.kr"
  "frontend-url"     = "https://app-staging.koneksi.co.kr"
  "log-level"        = "debug"
  "max-connections"  = "50"
}

secure_parameters = {
  "database-password" = "staging-db-password"
  "jwt-secret"       = "staging-jwt-secret-key"
  "github-token"     = "your_staging_github_token_here"
}
```

### Production Environment
```hcl
# envs/prod/terraform.tfvars
environment = "prod"

parameters = {
  "database-host"     = "prod-postgres.koneksi.internal"
  "redis-host"        = "prod-redis.cache.amazonaws.com"
  "api-url"          = "https://api.koneksi.co.kr"
  "frontend-url"     = "https://app.koneksi.co.kr"
  "log-level"        = "info"
  "max-connections"  = "200"
}

secure_parameters = {
  "database-password" = "production-secure-password"
  "jwt-secret"       = "production-jwt-secret-key"
  "github-token"     = "your_production_github_token_here"
}
```

## Security & Access Control

### IAM Policy for ECS Tasks
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:ap-southeast-1:*:parameter/koneksi/staging/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ssm.ap-southeast-1.amazonaws.com"
        }
      }
    }
  ]
}
```

### IAM Policy for CodeBuild
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": [
        "arn:aws:ssm:ap-southeast-1:*:parameter/koneksi/staging/github-token"
      ]
    }
  ]
}
```

## Cost Considerations

### Standard Parameters
- **Free Tier**: Up to 10,000 parameters
- **Overage**: $0.05 per 10,000 API calls
- **Storage**: No additional charges

### Secure Parameters
- **Cost**: $0.05 per 10,000 API calls
- **KMS**: Standard KMS key usage charges apply
- **Storage**: No additional charges

### Cost Optimization Tips
1. **Cache Parameters**: Cache frequently accessed parameters in application
2. **Batch Operations**: Use `GetParameters` for multiple parameters
3. **Parameter Hierarchies**: Use parameter paths for organized access
4. **Monitor Usage**: Use CloudWatch metrics to track API calls

## Best Practices

### Naming Conventions
1. **Use Hierarchical Names**: `/koneksi/{environment}/{service}/{parameter}`
2. **Lowercase with Hyphens**: `database-password` not `Database_Password`
3. **Descriptive Names**: `jwt-secret` not `secret1`
4. **Environment Separation**: Always include environment in path

### Security Practices
1. **Use Secure Parameters**: For any sensitive data
2. **Least Privilege IAM**: Grant minimal required permissions
3. **Regular Rotation**: Rotate secrets regularly
4. **Audit Access**: Monitor parameter access logs

### Operational Practices
1. **Version Management**: Use parameter versions for rollbacks
2. **Documentation**: Document parameter purpose and format
3. **Validation**: Validate parameter values in application
4. **Monitoring**: Set up CloudWatch alarms for parameter access

## Monitoring & Alerting

### CloudWatch Metrics
- **ParameterStoreApiCalls**: Number of API calls
- **ParameterStoreLatency**: API call latency
- **ParameterErrors**: Failed parameter retrievals

### Custom Monitoring
```hcl
resource "aws_cloudwatch_metric_alarm" "parameter_errors" {
  alarm_name          = "parameter-store-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "AWS/SSM"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Parameter Store error rate is high"
}
```

## Troubleshooting

### Common Issues

#### Parameter Not Found
```bash
# Check if parameter exists
aws ssm get-parameter --name "/koneksi/staging/database-host"

# List parameters by path
aws ssm get-parameters-by-path --path "/koneksi/staging/"
```

#### Access Denied
1. Check IAM permissions for the calling service
2. Verify KMS permissions for secure parameters
3. Ensure parameter path matches IAM policy

#### Decryption Errors
1. Verify KMS key permissions
2. Check if parameter is actually a SecureString
3. Ensure `WithDecryption=true` for secure parameters

## Dependencies

- **KMS**: For encrypting secure parameters
- **IAM**: For access control
- **CloudWatch**: For monitoring and logging

## Integration with Other Modules

- **ECS**: Container secrets and environment variables
- **CodePipeline**: Build-time configuration and secrets
- **Lambda**: Function configuration and secrets
- **API Gateway**: Custom domain and authentication configuration

## Maintenance

- **Regular Audits**: Review parameter usage and access patterns
- **Secret Rotation**: Implement regular secret rotation
- **Cleanup**: Remove unused parameters
- **Documentation**: Keep parameter documentation updated
- **Backup**: Export critical parameters for disaster recovery
- **Compliance**: Ensure parameters meet security compliance requirements

## Support

For issues related to:
- **Access Control**: Review IAM policies and permissions
- **Encryption**: Check KMS key policies and usage
- **Performance**: Monitor CloudWatch metrics and optimize caching
- **Security**: Review parameter classification and encryption settings
- **Cost**: Monitor API usage and implement caching strategies