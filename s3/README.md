# AWS S3 Module

This module provisions secure, encrypted S3 buckets with comprehensive lifecycle management, monitoring, and security features for the bongaquino infrastructure, primarily designed for Terraform state storage and general-purpose object storage.

## Overview

The S3 module creates production-ready S3 buckets with enterprise-grade security, automated lifecycle management, cross-origin resource sharing (CORS) support, and comprehensive monitoring. It implements AWS security best practices and provides flexible configuration options for various use cases.

## Features

- **Security**: KMS encryption, public access blocking, configurable bucket policies
- **Versioning**: Object versioning with configurable retention policies
- **Lifecycle Management**: Automated transitions to cost-effective storage classes
- **Monitoring**: CloudWatch alarms for bucket size and object count
- **CORS Support**: Configurable cross-origin resource sharing rules
- **Compliance**: SOC 2, PCI DSS, and GDPR compliance ready
- **Cost Optimization**: Intelligent tiering and lifecycle rules
- **Backup & Recovery**: Point-in-time recovery with versioning
- **Access Control**: Fine-grained IAM and bucket policy integration

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │    │   S3 Bucket     │    │      KMS        │
│   State Files   │───▶│   (Encrypted)   │───▶│   Encryption    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       ▼
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │   Versioning    │    │  Lifecycle      │
         │              │   (Point-in-    │    │  Rules          │
         │              │    Time Backup) │    │ (Cost Optimize) │
         │              └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudWatch    │    │   Public Access │    │   CORS          │
│   Monitoring    │    │   Blocking      │    │ Configuration   │
│   & Alarms      │    │   (Security)    │    │   (Optional)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Directory Structure

```
s3/
├── main.tf              # Main S3 configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── README.md           # This documentation
└── envs/               # Environment-specific configurations
    ├── staging/
    ├── uat/
    └── prod/
```

## Resources Created

### Core S3 Resources
- **aws_s3_bucket**: Main S3 bucket with lifecycle protection
- **aws_s3_bucket_versioning**: Object versioning configuration
- **aws_s3_bucket_server_side_encryption_configuration**: KMS encryption
- **aws_s3_bucket_public_access_block**: Security hardening
- **aws_s3_bucket_lifecycle_configuration**: Cost optimization rules

### Optional Resources
- **aws_s3_bucket_cors_configuration**: Cross-origin resource sharing
- **aws_s3_bucket_policy**: Custom access policies
- **aws_cloudwatch_metric_alarm**: Monitoring and alerting

## Usage

### Basic Terraform State Bucket

```hcl
module "terraform_state" {
  source = "./s3"
  
  # Basic configuration
  bucket_name = "bongaquino-terraform-state-unique-id"
  project     = "bongaquino"
  environment = "shared"
  aws_region  = "ap-southeast-1"
  
  # Security
  versioning_enabled = true
  kms_key_id         = "alias/aws/s3"
  
  # Monitoring
  bucket_size_threshold        = 10737418240  # 10GB
  number_of_objects_threshold  = 10000
  
  # Tags
  tags = {
    Purpose = "terraform-state"
    Team    = "devops"
  }
}
```

### Production Bucket with Lifecycle Management

```hcl
module "production_storage" {
  source = "./s3"
  
  # Basic configuration
  bucket_name = "bongaquino-prod-storage-unique-id"
  project     = "bongaquino"
  environment = "production"
  
  # Advanced lifecycle rules
  lifecycle_rules = [
    {
      id     = "cost-optimization"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      expiration = {
        days = 2555  # 7 years retention
      }
    }
  ]
  
  # Custom KMS key
  kms_key_id = "arn:aws:kms:ap-southeast-1:account:key/12345678-1234-1234-1234-123456789012"
  
  # Enhanced monitoring
  bucket_size_threshold       = 107374182400  # 100GB
  number_of_objects_threshold = 1000000       # 1M objects
}
```

### Web Assets Bucket with CORS

```hcl
module "web_assets" {
  source = "./s3"
  
  # Basic configuration
  bucket_name = "bongaquino-web-assets-unique-id"
  project     = "bongaquino"
  environment = "production"
  
  # CORS configuration for web assets
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = [
        "https://app.example.com",
        "https://app-staging.example.com"
      ]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
  
  # Public read access policy
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::bongaquino-web-assets-unique-id/*"
      }
    ]
  })
}
```

### Simple Deployment

1. **Edit configuration**:
```bash
# Edit terraform.tfvars
bucket_name = "your-globally-unique-bucket-name"
project     = "bongaquino"
environment = "shared"
```

2. **Deploy the bucket**:
```bash
cd bongaquino-aws/s3
terraform init
AWS_PROFILE=bongaquino terraform plan
AWS_PROFILE=bongaquino terraform apply
```

3. **Configure backend** (for Terraform state):
```hcl
# In your backend.tf files
terraform {
  backend "s3" {
    bucket = "your-globally-unique-bucket-name"
    key    = "path/to/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_name` | string | - | S3 bucket name (must be globally unique) |
| `aws_region` | string | `ap-southeast-1` | AWS region for deployment |
| `project` | string | `bongaquino` | Project name for tagging |
| `environment` | string | `staging` | Environment name for tagging |
| `name_prefix` | string | - | Prefix for resource names |

### Security & Encryption
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `versioning_enabled` | bool | `true` | Enable object versioning |
| `kms_key_id` | string | `null` | KMS key ARN for encryption (uses default if null) |
| `bucket_policy` | string | `null` | Custom JSON bucket policy |

### Lifecycle Management
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lifecycle_rules` | list(object) | `[]` | Lifecycle transition and expiration rules |

Example lifecycle rule:
```hcl
lifecycle_rules = [
  {
    id     = "cost-optimization"
    status = "Enabled"
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]
    expiration = {
      days = 365
    }
  }
]
```

### CORS Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cors_rules` | list(object) | `[]` | Cross-origin resource sharing rules |

Example CORS rule:
```hcl
cors_rules = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "POST"]
    allowed_origins = ["https://app.example.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
]
```

### Monitoring
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_size_threshold` | number | `1073741824` | Bucket size alarm threshold (bytes) |
| `number_of_objects_threshold` | number | `1000` | Object count alarm threshold |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_name` | The name of the S3 bucket |
| `bucket_arn` | The ARN of the S3 bucket |
| `bucket_domain_name` | The bucket domain name |
| `bucket_regional_domain_name` | The bucket regional domain name |
| `bucket_id` | The bucket ID |
| `bucket_hosted_zone_id` | The hosted zone ID for the bucket |

## Security Features

### Encryption at Rest
- **KMS Encryption**: Server-side encryption using AWS KMS
- **Custom Keys**: Support for customer-managed KMS keys
- **Default Encryption**: Enforced encryption for all objects
- **Key Rotation**: Automatic key rotation with AWS-managed keys

### Access Control
- **Public Access Blocking**: All public access blocked by default
- **Bucket Policies**: Configurable fine-grained access control
- **IAM Integration**: Works with IAM roles and policies
- **VPC Endpoints**: Support for private access via VPC endpoints

### Security Configuration
```hcl
# Public access is completely blocked
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

# Encryption is enforced
sse_algorithm     = "aws:kms"
kms_master_key_id = var.kms_key_id
```

### Versioning & Backup
- **Object Versioning**: Full version history for all objects
- **Point-in-Time Recovery**: Restore to any previous version
- **Accidental Deletion Protection**: Versioning prevents data loss
- **Cross-Region Replication**: Optional for disaster recovery

## Storage Classes & Lifecycle Management

### Available Storage Classes
- **Standard**: Frequent access, low latency
- **Standard-IA**: Infrequent access, lower cost
- **Glacier**: Long-term archival, retrieval in minutes
- **Glacier Deep Archive**: Lowest cost, retrieval in hours

### Lifecycle Transition Example
```hcl
lifecycle_rules = [
  {
    id     = "comprehensive-lifecycle"
    status = "Enabled"
    transitions = [
      {
        days          = 30    # After 30 days
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90    # After 90 days
        storage_class = "GLACIER"
      },
      {
        days          = 365   # After 1 year
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    expiration = {
      days = 2555  # Delete after 7 years
    }
  }
]
```

### Cost Optimization
- **Intelligent Tiering**: Automatic cost optimization
- **Lifecycle Policies**: Automated transitions to cheaper storage
- **Monitoring**: Track storage costs and usage patterns
- **Compression**: Client-side compression recommended

## Monitoring & Alerting

### CloudWatch Metrics
- **BucketSizeBytes**: Total bucket size monitoring
- **NumberOfObjects**: Object count tracking
- **AllRequests**: Request volume monitoring
- **4xxErrors/5xxErrors**: Error rate monitoring

### Alarms Configuration
```hcl
# Bucket size alarm
bucket_size_threshold = 10737418240  # 10GB

# Object count alarm  
number_of_objects_threshold = 10000
```

### Log Analysis
- **Server Access Logs**: Detailed request logging
- **CloudTrail Integration**: API call auditing
- **Cost and Usage Reports**: Detailed cost breakdown
- **Performance Monitoring**: Request latency tracking

## Compliance & Governance

### Compliance Standards
- **SOC 2**: Security controls and monitoring
- **PCI DSS**: Payment card industry compliance
- **GDPR**: European data protection regulation
- **HIPAA**: Healthcare data protection (with proper configuration)

### Data Governance
- **Object Tagging**: Metadata for data classification
- **Lifecycle Policies**: Automated data retention
- **Access Logging**: Complete audit trail
- **Encryption**: Data protection at rest and in transit

## Performance Optimization

### Request Performance
- **Transfer Acceleration**: Global content delivery
- **Multipart Uploads**: Parallel upload for large files
- **Request Rate**: 3,500 PUT/COPY/POST/DELETE and 5,500 GET/HEAD per prefix
- **Prefix Distribution**: Distribute load across multiple prefixes

### Best Practices
1. **Use Random Prefixes**: Avoid hotspotting
2. **Multipart Uploads**: For files > 100MB
3. **CloudFront Integration**: Cache frequently accessed content
4. **Compression**: Compress objects before upload
5. **Batch Operations**: Use S3 batch operations for bulk tasks

## Cost Management

### Storage Costs
- **Standard**: $0.023 per GB/month
- **Standard-IA**: $0.0125 per GB/month
- **Glacier**: $0.004 per GB/month
- **Deep Archive**: $0.00099 per GB/month

### Request Costs
- **PUT/POST**: $0.0004 per 1,000 requests
- **GET/HEAD**: $0.00004 per 1,000 requests
- **Lifecycle Transitions**: $0.01 per 1,000 requests

### Cost Optimization Strategies
1. **Lifecycle Policies**: Automatic cost optimization
2. **Storage Class Analysis**: Monitor access patterns
3. **Request Optimization**: Minimize unnecessary requests
4. **Compression**: Reduce storage footprint
5. **Monitoring**: Track costs and usage patterns

## Troubleshooting

### Common Issues

#### Bucket Name Already Exists
```
Error: BucketAlreadyExists
```
**Solution**: S3 bucket names must be globally unique. Choose a different name.

#### Access Denied Errors
```
Error: AccessDenied
```
**Solution**: 
1. Check IAM permissions
2. Verify bucket policy configuration
3. Ensure public access blocks are configured correctly

#### Encryption Issues
```
Error: KMS key not found
```
**Solution**:
1. Verify KMS key ARN is correct
2. Check KMS key permissions
3. Ensure key is in the same region as bucket

### Debugging Commands
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket your-bucket-name

# Verify encryption configuration
aws s3api get-bucket-encryption --bucket your-bucket-name

# Check versioning status
aws s3api get-bucket-versioning --bucket your-bucket-name

# List objects with versions
aws s3api list-object-versions --bucket your-bucket-name

# Monitor bucket metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=your-bucket-name \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 86400 \
  --statistics Average
```

## Best Practices

### Security
1. **Enable Versioning**: Protect against accidental deletion
2. **Use KMS Encryption**: Encrypt all sensitive data
3. **Block Public Access**: Never allow public access unless specifically needed
4. **Regular Audits**: Review access patterns and permissions
5. **Multi-Factor Authentication**: Require MFA for sensitive operations

### Performance
1. **Use Transfer Acceleration**: For global users
2. **Optimize Request Patterns**: Distribute load across prefixes
3. **Implement Compression**: Reduce storage and transfer costs
4. **Use CloudFront**: Cache frequently accessed content
5. **Monitor Performance**: Track request latency and error rates

### Cost Optimization
1. **Lifecycle Policies**: Automate transitions to cheaper storage
2. **Monitor Usage**: Regular cost and usage analysis
3. **Delete Unnecessary Data**: Regular cleanup of unused objects
4. **Use Intelligent Tiering**: Automatic cost optimization
5. **Compress Data**: Reduce storage footprint

## Dependencies

- **KMS**: For object encryption (optional)
- **CloudWatch**: For monitoring and alerting
- **IAM**: For access control and permissions
- **VPC**: For private access via VPC endpoints (optional)

## Integration with Other Modules

- **CloudWatch**: Monitoring and alerting
- **KMS**: Encryption key management
- **IAM**: Access control and permissions
- **VPC**: Private network access
- **CloudFront**: Content delivery and caching

## Maintenance

- **Regular Monitoring**: Review CloudWatch metrics and alarms
- **Cost Analysis**: Monthly cost review and optimization
- **Security Audits**: Regular security configuration reviews
- **Performance Review**: Monitor and optimize request patterns
- **Data Lifecycle**: Review and update lifecycle policies
- **Backup Verification**: Test restore procedures regularly

## Support

For issues related to:
- **Configuration**: Review Terraform configuration and AWS console
- **Permissions**: Check IAM roles, policies, and bucket policies
- **Performance**: Analyze CloudWatch metrics and access patterns
- **Costs**: Monitor usage patterns and optimize lifecycle policies
- **Security**: Review encryption and access control configurations 