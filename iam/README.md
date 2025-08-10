# AWS IAM Module

This module provisions comprehensive Identity and Access Management (IAM) infrastructure with role-based access control, security best practices, and enterprise-grade compliance features. It provides centralized user management, fine-grained permissions, and automated security controls for multi-team AWS environments.

## Overview

The IAM module creates a secure, scalable identity management system that implements least privilege access, automated compliance monitoring, and comprehensive audit trails. It supports multiple teams, environments, and access patterns while maintaining security best practices and regulatory compliance.

## Features

- **Multi-Team Support**: Separate groups for developers, operations, and management teams
- **Role-Based Access Control**: Fine-grained permissions based on job functions
- **Least Privilege Principle**: Minimum required permissions for each role
- **Automated User Management**: Programmatic user creation and access key management
- **Custom Policy Support**: Tailored policies for specific AWS services
- **Cross-Team Collaboration**: Secure resource sharing between teams
- **Compliance Ready**: Built-in compliance controls and audit trails
- **Access Key Rotation**: Automated access key lifecycle management
- **MFA Integration**: Multi-factor authentication support for enhanced security
- **Temporary Access**: Session-based temporary credentials

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            IAM Account Structure                            │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Management    │  │   Operations    │  │       Developers            │ │
│  │     Group       │  │     Group       │  │        Groups               │ │
│  │                 │  │                 │  │                             │ │
│  │ • Admin Access  │  │ • Admin Access  │  │  • PowerUser Access         │ │
│  │ • Billing       │  │ • Infrastructure│  │  • Service-specific Access  │ │
│  │ • Compliance    │  │ • Security      │  │  • Development Resources    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
│           │                    │                          │                │
└───────────┼────────────────────┼──────────────────────────┼────────────────┘
            │                    │                          │                
            ▼                    ▼                          ▼                
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Users & Access Keys                               │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │    Managers     │  │   DevOps Team   │  │       Dev Teams             │ │
│  │                 │  │                 │  │                             │ │
│  │ • CEO           │  │ • Site Reliability│  │  • Frontend Developers     │ │
│  │ • CTO           │  │ • Platform Eng  │  │  • Backend Developers       │ │
│  │ • Security Lead │  │ • Cloud Architect│  │  • Mobile Developers        │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
            │                    │                          │                
            ▼                    ▼                          ▼                
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Custom Policies                                    │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Amplify       │  │  SSM Parameter  │  │       Service               │ │
│  │  Full Access    │  │  Store Access   │  │    Specific Policies        │ │
│  │                 │  │                 │  │                             │ │
│  │ • App Management│  │ • Config Mgmt   │  │  • S3 Bucket Policies       │ │
│  │ • Deployment    │  │ • Secret Storage│  │  • DynamoDB Table Access    │ │
│  │ • Domain Config │  │ • Parameter CRUD│  │  • Lambda Function Policies │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
iam/
├── README.md                    # This documentation
├── main.tf                      # Core IAM resources
├── variables.tf                 # Input variables
├── outputs.tf                   # Module outputs
├── locals.tf                    # Local configurations and user definitions
├── backend.tf                   # Backend configuration
├── terraform.tfvars             # Variable values
├── iam-accounts.md             # Account management documentation
└── docs/                        # Additional documentation
    └── access-patterns.md      # Access pattern documentation
```

## Resources Created

### Core IAM Resources
- **aws_iam_group**: Role-based groups for different team functions
- **aws_iam_user**: Individual user accounts with secure configurations
- **aws_iam_access_key**: Programmatic access credentials
- **aws_iam_group_membership**: User-to-group associations

### Custom Policies
- **aws_iam_policy**: Service-specific custom policies
- **aws_iam_group_policy_attachment**: Policy-to-group associations
- **aws_iam_user_policy_attachment**: Direct user policy attachments

### Security Features
- **aws_iam_account_password_policy**: Account-wide password requirements
- **aws_iam_role**: Service roles for AWS resources
- **aws_iam_instance_profile**: EC2 instance profiles

## Team Structure & Permissions

### Management Group
**Members**: C-level executives, senior leadership
**Permissions**: 
- Administrator Access (full AWS permissions)
- Billing and cost management
- Organization management
- Compliance and audit access

**AWS Managed Policies**:
- `AdministratorAccess`
- `Billing`
- `AWSSupportAccess`

### Operations Group  
**Members**: DevOps engineers, SRE team, infrastructure specialists
**Permissions**:
- Administrator Access for infrastructure management
- Full deployment and monitoring capabilities
- Security configuration and management
- Backup and disaster recovery operations

**AWS Managed Policies**:
- `AdministratorAccess`
- `AWSSupportAccess`

### Developers Group (bongaquino)
**Members**: Application developers, frontend/backend engineers
**Permissions**:
- PowerUser Access (most services except IAM management)
- Development environment full access
- Limited production environment access
- Code deployment through CI/CD pipelines

**AWS Managed Policies**:
- `PowerUserAccess`

**Custom Policies**:
- Amplify full access for frontend deployments
- SSM Parameter Store read/write for configuration

### bongaquino Developers Group
**Members**: bongaquino team developers and contractors
**Permissions**:
- PowerUser Access scoped to bongaquino resources
- Isolated development environments
- Limited cross-team resource access

**AWS Managed Policies**:
- `PowerUserAccess`

**Resource Isolation**:
- Resource tagging for team separation
- Conditional access based on resource tags

## Usage

### Basic User Management

```hcl
# Define users in terraform.tfvars or locals.tf
users = {
  "developer1" = {
    username   = "john.doe-bongaquino"
    department = "developers"
<<<<<<< HEAD
    team       = "bongaquino"
=======
    team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
    email      = "john.doe@bongaquino.co.kr"
    role       = "Developer"
  }
  "devops1" = {
    username   = "jane.smith-bongaquino"
    department = "devops"
<<<<<<< HEAD
    team       = "bongaquino" 
=======
    team       = "bongaquino" 
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
    email      = "jane.smith@bongaquino.co.kr"
    role       = "Operations"
  }
  "manager1" = {
    username   = "mike.johnson-bongaquino"
    department = "management"
<<<<<<< HEAD
    team       = "bongaquino"
=======
    team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
    email      = "mike.johnson@bongaquino.co.kr"
    role       = "Management"
  }
}
```

### Multi-Team Setup

```hcl
# bongaquino team members
locals {
  bongaquino_users = {
    "frontend_dev" = {
      username   = "alex.kim-bongaquino"
      department = "developers"
<<<<<<< HEAD
      team       = "bongaquino"
=======
      team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
      email      = "alex.kim@bongaquino.co.kr"
      role       = "Developer"
    }
    "backend_dev" = {
      username   = "sarah.lee-bongaquino"
      department = "developers"
<<<<<<< HEAD
      team       = "bongaquino"
=======
      team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
      email      = "sarah.lee@bongaquino.co.kr"
      role       = "Developer"
    }
  }

  # bongaquino team members
  bongaquino_users = {
    "data_engineer" = {
      username   = "david.park-bongaquino"
      department = "developers"
<<<<<<< HEAD
      team       = "bongaquino"
=======
      team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
      email      = "david.park@bongaquino.com"
      role       = "Developer"
    }
  }

  # Merge all users
  all_users = merge(
    local.bongaquino_users,
    local.bongaquino_users
  )
}
```

### Custom Policy Creation

```hcl
# Service-specific access policy
resource "aws_iam_policy" "s3_bucket_access" {
  name        = "S3BucketSpecificAccess"
  description = "Access to specific S3 buckets for development"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::bongaquino-dev-*/*",
          "arn:aws:s3:::bongaquino-dev-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::bongaquino-dev-*",
          "arn:aws:s3:::bongaquino-dev-*"
        ]
      }
    ]
  })
}
```

### Environment-Specific Permissions

```hcl
# Development environment access
resource "aws_iam_policy" "development_resources" {
  name = "DevelopmentEnvironmentAccess"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "lambda:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
          }
          StringLike = {
            "ec2:ResourceTag/Environment" = ["dev", "staging"]
          }
        }
      }
    ]
  })
}
```

### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply configuration
terraform apply -var-file="terraform.tfvars"

# Retrieve access keys (sensitive output)
terraform output -json user_access_keys | jq -r '.["user1"].secret'

# List all users
terraform output user_arns
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"ap-southeast-1"` | AWS region for resources |
| `users` | map(object) | `{}` | Map of users with their configurations |

### User Object Structure
```hcl
{
  username   = string  # IAM username (must be unique)
  department = string  # Department/team assignment
  team       = string  # Team identifier
  email      = string  # User email address
  role       = string  # Role assignment (Developer/Operations/Management)
}
```

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `user_access_keys` | Map of usernames to their access keys (sensitive) |
| `user_secret_keys` | Map of usernames to their secret keys (sensitive) |
| `user_arns` | Map of usernames to their ARNs |
| `user_names` | List of all created usernames |
| `group_arns` | Map of group names to their ARNs |
| `group_names` | List of all group names |
| `policy_arns` | Map of custom policy names to their ARNs |

## Security Features

### Access Key Management
```hcl
# Automated access key rotation
resource "aws_iam_access_key" "user_keys" {
  for_each = var.users
  user     = aws_iam_user.users[each.key].name
  
  # Access key rotation strategy
  lifecycle {
    create_before_destroy = true
  }
}
```

### Password Policy
```hcl
# Account-wide password policy
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters  = true
  require_symbols              = true
  allow_users_to_change_password = true
  max_password_age             = 90
  password_reuse_prevention    = 12
}
```

### MFA Enforcement
```hcl
# MFA enforcement policy
resource "aws_iam_policy" "mfa_enforcement" {
  name = "MFAEnforcement"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
          DateGreaterThan = {
            "aws:TokenIssueTime" = "2023-01-01T00:00:00Z"
          }
        }
      }
    ]
  })
}
```

## Monitoring & Compliance

### CloudWatch Monitoring
```hcl
# Failed login attempt monitoring
resource "aws_cloudwatch_metric_alarm" "failed_logins" {
  alarm_name          = "iam-failed-login-attempts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedLoginAttempts"
  namespace           = "AWS/IAM"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Monitor IAM failed login attempts"
  
  alarm_actions = [aws_sns_topic.security_alerts.arn]
}

# Unusual access pattern detection
resource "aws_cloudwatch_metric_alarm" "unusual_access" {
  alarm_name          = "iam-unusual-access-pattern"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AccessKeyUsage"
  namespace           = "AWS/IAM"
  period              = "900"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Monitor unusual access key usage patterns"
}
```

### Compliance Reporting
```bash
# Generate IAM compliance report
aws iam generate-credential-report

# Get credential report
aws iam get-credential-report --output text --query 'Content' | base64 -d > iam-credential-report.csv

# List users with MFA status
aws iam list-users --query 'Users[*].[UserName,CreateDate]' --output table

# Check access key age
aws iam list-access-keys --user-name username --query 'AccessKeyMetadata[*].[AccessKeyId,CreateDate,Status]'
```

## Best Practices Implementation

### Least Privilege Access
```hcl
# Resource-based conditions
resource "aws_iam_policy" "restricted_s3_access" {
  name = "RestrictedS3Access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::${var.team}-${var.environment}-*/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}
```

### Session Management
```hcl
# Temporary session tokens
resource "aws_iam_role" "temporary_access" {
  name = "TemporaryDeveloperAccess"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [for user in aws_iam_user.users : user.arn]
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
          }
          NumericLessThan = {
            "aws:TokenIssueTime" = "3600"  # 1 hour session
          }
        }
      }
    ]
  })
}
```

### Automated Cleanup
```bash
#!/bin/bash
# Script to identify and clean up unused access keys

# Find unused access keys (older than 90 days with no recent activity)
aws iam list-users --query 'Users[*].UserName' --output text | while read username; do
  aws iam list-access-keys --user-name "$username" --query 'AccessKeyMetadata[?CreateDate<`2023-01-01`].[AccessKeyId,CreateDate]' --output text
done

# Rotate access keys for active users
for user in $(aws iam list-users --query 'Users[*].UserName' --output text); do
  # Create new access key
  new_key=$(aws iam create-access-key --user-name "$user" --query 'AccessKey.AccessKeyId' --output text)
  
  # Wait for propagation
  sleep 30
  
  # Delete old access key (after verifying new key works)
  old_keys=$(aws iam list-access-keys --user-name "$user" --query 'AccessKeyMetadata[?CreateDate<`2023-06-01`].AccessKeyId' --output text)
  for old_key in $old_keys; do
    aws iam delete-access-key --user-name "$user" --access-key-id "$old_key"
  done
done
```

## Troubleshooting

### Common Issues

#### Access Denied Errors
**Symptoms**: Users unable to access AWS resources
**Solutions**:
1. Verify user group membership
2. Check policy attachments
3. Review resource-based policies
4. Confirm MFA requirements

#### Policy Conflicts
**Symptoms**: Unexpected permission denials
**Solutions**:
1. Use IAM Policy Simulator to test permissions
2. Check for explicit deny statements
3. Review policy precedence (explicit deny > explicit allow > implicit deny)
4. Validate condition blocks

#### Access Key Issues
**Symptoms**: Programmatic access failures
**Solutions**:
1. Verify access key status (active/inactive)
2. Check secret key configuration
3. Confirm regional service availability
4. Review temporary credential expiration

### Debugging Commands

```bash
# Test user permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::account:user/username \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::bucket/*

# Check effective permissions
aws iam get-account-authorization-details \
  --filter User \
  --query 'UserDetailList[?UserName==`username`]'

# Validate access key
aws sts get-caller-identity

# Check group memberships
aws iam get-groups-for-user --user-name username

# List attached policies
aws iam list-attached-user-policies --user-name username
aws iam list-user-policies --user-name username
```

## Dependencies

- **AWS Organizations**: Account management and service control policies
- **CloudTrail**: API call logging and audit trails
- **CloudWatch**: Monitoring and alerting
- **SNS**: Security alert notifications
- **KMS**: Key management for encryption

## Integration with Other Modules

- **EC2**: Instance profiles and service roles
- **S3**: Bucket policies and cross-account access
- **Lambda**: Execution roles and function permissions
- **RDS**: Database access and encryption
- **VPC**: Network-based access controls

## Maintenance

- **Access Review**: Quarterly access rights review
- **Key Rotation**: Automated 90-day access key rotation
- **Policy Updates**: Regular policy updates based on service changes
- **Compliance Audits**: Annual compliance and security audits
- **User Lifecycle**: Automated onboarding/offboarding processes

## Support

For issues related to:
- **Access Control**: Review IAM policies and group memberships
- **Authentication**: Check MFA settings and password policies
- **Permissions**: Use IAM Policy Simulator for troubleshooting
- **Compliance**: Review audit logs and access patterns
- **Integration**: Verify service roles and cross-service permissions

## Security Considerations

1. Access keys are created for each user and should be securely distributed
2. Users are automatically added to appropriate groups based on their department
3. Policies follow the principle of least privilege
4. All resources are tagged for better management

## Outputs

- `user_access_keys`: Map of usernames to their access keys (sensitive)
- `user_arns`: Map of usernames to their ARNs
- `group_arns`: Map of group names to their ARNs

## Best Practices

1. Rotate access keys regularly
2. Review and update permissions as needed
3. Use IAM roles for EC2 instances when possible
4. Monitor IAM activity through CloudTrail
5. Regularly audit user permissions 