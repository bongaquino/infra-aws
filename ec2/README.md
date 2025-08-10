# AWS EC2 Module

This module provisions and manages Amazon EC2 instances with comprehensive security, monitoring, and operational features. It provides flexible instance configurations, automated backup strategies, security hardening, and centralized management for compute resources across multiple environments.

## Overview

The EC2 module creates production-ready virtual machines with enterprise-grade security, automated patching, monitoring integration, and cost optimization features. It supports various instance types, storage configurations, and deployment patterns from bastion hosts to application servers.

## Features

- **Multiple Instance Types**: Support for various EC2 instance families and sizes
- **Automated Security**: Security group management, encrypted storage, and secure SSH access
- **High Availability**: Multi-AZ deployment support with automatic recovery
- **Cost Optimization**: Right-sizing recommendations and automated scheduling
- **Backup & Recovery**: Automated EBS snapshots and AMI creation
- **Monitoring Integration**: CloudWatch metrics, logs, and custom dashboards
- **Patch Management**: Automated OS patching and security updates
- **Key Management**: Secure SSH key rotation and access control
- **Elastic IP**: Static IP addresses for consistent connectivity
- **Storage Optimization**: Multiple storage types with encryption support

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             VPC Network                                     │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │  Public Subnet  │  │ Private Subnet  │  │     Private Subnet          │ │
│  │     (AZ-a)      │  │     (AZ-a)      │  │        (AZ-b)               │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │  ┌─────────────────────────┐│ │
│  │ │   Bastion   │ │  │ │ Application │ │  │  │      Database           ││ │
│  │ │   Host      │ │  │ │   Servers   │ │  │  │      Servers            ││ │
│  │ │  (Public)   │ │  │ │  (Private)  │ │  │  │     (Private)           ││ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │  └─────────────────────────┘│ │
│  │       │         │  │       │         │  │            │                │ │
│  └───────┼─────────┘  └───────┼─────────┘  └────────────┼────────────────┘ │
│          │                    │                         │                  │
└──────────┼────────────────────┼─────────────────────────┼──────────────────┘
           │                    │                         │                  
           ▼                    ▼                         ▼                  
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Security & Management                               │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │  Security       │  │   Monitoring    │  │      Backup & Recovery      │ │
│  │   Groups        │  │  (CloudWatch)   │  │                             │ │
│  │                 │  │                 │  │  • EBS Snapshots            │ │
│  │ • SSH Access    │  │ • Instance      │  │  • AMI Creation             │ │
│  │ • Port Rules    │  │   Metrics       │  │  • Point-in-time Recovery   │ │
│  │ • IP Whitelisting│  │ • Custom Logs   │  │  • Cross-region Backups     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
           │                    │                         │                  
           ▼                    ▼                         ▼                  
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Management Tools                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   SSH Key       │  │     Patch       │  │       Cost                  │ │
│  │  Management     │  │   Management    │  │    Optimization             │ │
│  │                 │  │                 │  │                             │ │
│  │ • Key Rotation  │  │ • Auto Updates  │  │  • Instance Scheduling      │ │
│  │ • Access Control│  │ • Security      │  │  • Right-sizing             │ │
│  │ • Audit Logging │  │   Patches       │  │  • Reserved Instances       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
ec2/
├── README.md                    # This documentation
├── main.tf                      # Core EC2 resources
├── variables.tf                 # Input variables
├── outputs.tf                   # Module outputs
├── backend.tf                   # Backend configuration
├── versions.tf                  # Provider version constraints
├── modules/                     # Reusable sub-modules
│   ├── instance/               # EC2 instance module
│   │   ├── main.tf             # Instance configuration
│   │   ├── variables.tf        # Instance variables
│   │   └── outputs.tf          # Instance outputs
│   └── key_pair/               # SSH key management
│       ├── main.tf             # Key pair configuration
│       ├── variables.tf        # Key variables
│       └── outputs.tf          # Key outputs
├── scripts/                     # Automation scripts
│   ├── rotate_keys.sh          # Key rotation automation
│   ├── manage_key_access.sh    # Access management
│   ├── instance_backup.sh      # Backup automation
│   └── cost_optimization.sh    # Cost optimization tools
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

### Core EC2 Resources
- **aws_instance**: EC2 virtual machines with customizable configurations
- **aws_eip**: Elastic IP addresses for static connectivity
- **aws_ebs_volume**: Additional storage volumes with encryption
- **aws_volume_attachment**: EBS volume attachments

### Security Resources
- **aws_security_group**: Network access control rules
- **aws_key_pair**: SSH key management for secure access
- **aws_ebs_encryption_by_default**: Account-wide EBS encryption

### Monitoring & Management
- **aws_cloudwatch_metric_alarm**: Instance health and performance monitoring
- **aws_backup_plan**: Automated backup scheduling
- **aws_backup_vault**: Secure backup storage
- **aws_ssm_document**: Patch management and automation

## Usage

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version >= 1.0.0)
3. S3 bucket for Terraform state
4. DynamoDB table for state locking

### Environment Setup

1. Choose an environment (staging, uat, prod)
2. Navigate to the environment directory:
   ```bash
   cd envs/<environment>
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

### Key Management

See [Key Management Documentation](keys/README.md) for details on:
- Key rotation
- Access management
- Security best practices

## Usage

### Basic Bastion Host Setup

```hcl
module "bastion_host" {
  source = "./ec2"

  # Basic configuration
  ami_id             = "ami-0c55b159cbfafe1d0"  # Latest Amazon Linux 2
  instance_type      = "t3.micro"
  key_name           = "bongaquino-staging-key"
  
  # Network configuration
  public_subnet_id   = module.vpc.public_subnet_ids[0]
  public_sg_id       = module.security_groups.bastion_sg_id
  
  # Storage configuration
  root_volume_size   = 20
  root_volume_type   = "gp3"
  
  # Environment
  environment        = "staging"
<<<<<<< HEAD
  project           = "bongaquino"
=======
  project           = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  name_prefix       = "bongaquino-staging"
  
  tags = {
    Environment = "staging"
<<<<<<< HEAD
    Project     = "bongaquino"
=======
    Project     = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
    Purpose     = "bastion-host"
  }
}
```

### Production Setup with Enhanced Security

```hcl
module "production_instances" {
  source = "./ec2"

  # Production-grade configuration
  ami_id             = "ami-0c55b159cbfafe1d0"
  instance_type      = "t3.medium"
  key_name           = "bongaquino-prod-key"
  
  # Network configuration
  public_subnet_id   = module.vpc.public_subnet_ids[0]
  public_sg_id       = module.security_groups.restricted_sg_id
  
  # Enhanced storage
  root_volume_size   = 50
  root_volume_type   = "gp3"
  
  # Production settings
  environment        = "production"
<<<<<<< HEAD
  project           = "bongaquino"
=======
  project           = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  name_prefix       = "bongaquino-prod"
  
  # Enhanced monitoring and backup
  enable_detailed_monitoring = true
  enable_backup             = true
  backup_retention_days     = 30
  
  tags = {
    Environment     = "production"
<<<<<<< HEAD
    Project         = "bongaquino"
=======
    Project         = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
    CriticalLevel   = "high"
    BackupRequired  = "true"
  }
}
```

### Multi-Instance Application Deployment

```hcl
# Web servers
module "web_servers" {
  count  = 2
  source = "./ec2"

  ami_id           = data.aws_ami.web_server.id
  instance_type    = "t3.small"
  key_name         = "bongaquino-web-key"
  public_subnet_id = module.vpc.public_subnet_ids[count.index]
  public_sg_id     = module.security_groups.web_sg_id
  
  environment      = "production"
  name_prefix      = "bongaquino-web-${count.index + 1}"
  
  tags = {
    Role = "web-server"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Database servers
module "db_servers" {
  count  = 2
  source = "./ec2"

  ami_id           = data.aws_ami.db_server.id
  instance_type    = "r5.large"
  key_name         = "bongaquino-db-key"
  public_subnet_id = module.vpc.private_subnet_ids[count.index]
  public_sg_id     = module.security_groups.db_sg_id
  
  root_volume_size = 100
  root_volume_type = "io2"
  
  environment      = "production"
  name_prefix      = "bongaquino-db-${count.index + 1}"
  
  tags = {
    Role = "database-server"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ami_id` | string | - | AMI ID for the EC2 instance |
| `instance_type` | string | `"t3.micro"` | Instance type for the EC2 instance |
| `key_name` | string | - | Name of the SSH key pair |
| `name_prefix` | string | - | Prefix for resource names |

### Network Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `public_subnet_id` | string | - | ID of the subnet to launch the instance |
| `public_sg_id` | string | - | ID of the security group |
| `aws_region` | string | `"ap-southeast-1"` | AWS region for resources |

### Storage Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `root_volume_size` | number | `8` | Size of the root volume in GB |
| `root_volume_type` | string | `"gp3"` | Type of the root volume |
| `enable_encryption` | bool | `true` | Enable EBS encryption |

### Environment & Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | string | `"staging"` | Environment name for tagging |
| `project` | string | `"bongaquino"` | Project name for tagging |
| `tags` | map(string) | `{}` | Additional tags for all resources |

### Advanced Options
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_detailed_monitoring` | bool | `false` | Enable detailed CloudWatch monitoring |
| `enable_backup` | bool | `true` | Enable automated backups |
| `backup_retention_days` | number | `7` | Backup retention period |
| `associate_public_ip` | bool | `true` | Associate public IP address |
| `disable_api_termination` | bool | `false` | Enable termination protection |

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | ID of the EC2 instance |
| `instance_arn` | ARN of the EC2 instance |
| `public_ip` | Public IP address of the instance |
| `private_ip` | Private IP address of the instance |
| `public_dns` | Public DNS name of the instance |
| `private_dns` | Private DNS name of the instance |
| `elastic_ip` | Elastic IP address (if created) |
| `elastic_ip_association_id` | Elastic IP association ID |
| `security_group_id` | ID of the instance security group |
| `key_pair_name` | Name of the SSH key pair |
| `subnet_id` | ID of the subnet where instance is launched |
| `availability_zone` | Availability zone of the instance |

## Security Features

### Encryption & Data Protection
- **EBS Encryption**: All volumes encrypted at rest with AWS KMS
- **Encryption in Transit**: TLS/SSL for all communications
- **Key Management**: Automated SSH key rotation and secure storage
- **Instance Metadata**: IMDSv2 enforced for enhanced security

### Network Security
```hcl
# Security group configuration example
resource "aws_security_group" "bastion" {
  name        = "bongaquino-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # SSH access from specific IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs  # Restrict to company IPs
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bongaquino-bastion-sg"
  }
}
```

### Access Control
- **IAM Integration**: Role-based access control
- **SSH Key Management**: Centralized key distribution
- **Session Logging**: All SSH sessions logged via CloudTrail
- **Multi-Factor Authentication**: MFA requirements for sensitive operations

## Monitoring & Alerting

### CloudWatch Integration
```hcl
# Instance monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "bongaquino-instance-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    InstanceId = aws_instance.bastion.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Instance status monitoring
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "bongaquino-instance-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Instance status check failed"

  dimensions = {
    InstanceId = aws_instance.bastion.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### Custom Dashboards
```hcl
resource "aws_cloudwatch_dashboard" "ec2_monitoring" {
  dashboard_name = "EC2-${var.environment}-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.bastion.id],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."],
            [".", "DiskReadOps", ".", "."],
            [".", "DiskWriteOps", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Instance Metrics"
        }
      }
    ]
  })
}
```

## Backup & Recovery

### Automated Backup Strategy
```hcl
# Backup plan
resource "aws_backup_plan" "ec2_backup" {
  name = "bongaquino-ec2-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.ec2_vault.name
    schedule          = "cron(0 2 ? * * *)"  # Daily at 2 AM

    recovery_point_tags = {
      Environment = var.environment
      Project     = var.project
    }

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }
  }
}

# Backup vault
resource "aws_backup_vault" "ec2_vault" {
  name        = "bongaquino-ec2-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}
```

### Point-in-Time Recovery
```bash
# Create manual snapshot
aws ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "Manual backup before maintenance"

# Restore from snapshot
aws ec2 create-volume \
  --snapshot-id snap-1234567890abcdef0 \
  --availability-zone us-west-2a \
  --volume-type gp3
```

## Cost Optimization

### Instance Right-Sizing
```hcl
# Cost-optimized instance types by workload
locals {
  instance_types = {
    "development" = "t3.micro"    # Burstable performance
    "staging"     = "t3.small"    # Light workloads
    "production"  = "t3.medium"   # Balanced performance
    "compute"     = "c5.large"    # Compute-optimized
    "memory"      = "r5.large"    # Memory-optimized
  }
}
```

### Automated Scheduling
```hcl
# Auto-stop instances during off-hours
resource "aws_lambda_function" "instance_scheduler" {
  filename         = "instance_scheduler.zip"
  function_name    = "bongaquino-instance-scheduler"
  role            = aws_iam_role.scheduler_role.arn
  handler         = "scheduler.lambda_handler"
  runtime         = "python3.9"

  environment {
    variables = {
      INSTANCE_IDS = join(",", [aws_instance.bastion.id])
      TIMEZONE     = "Asia/Singapore"
    }
  }
}

# CloudWatch Events for scheduling
resource "aws_cloudwatch_event_rule" "stop_instances" {
  name                = "stop-instances"
  description         = "Stop instances at 6 PM weekdays"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
}
```

### Cost Monitoring
```bash
# Monitor instance costs
aws ce get-cost-and-usage \
  --time-period Start=2023-01-01,End=2023-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://ec2-filter.json
```

## Troubleshooting

### Common Issues

#### Instance Connection Problems
**Symptoms**: Unable to SSH to instance
**Solutions**:
1. Check security group rules for SSH (port 22)
2. Verify key pair is correct and has proper permissions
3. Ensure instance is in running state
4. Check network ACLs and routing

#### High CPU Utilization
**Symptoms**: Instance performance degradation
**Solutions**:
1. Identify resource-intensive processes
2. Scale up instance type if needed
3. Optimize application performance
4. Consider load balancing

#### Storage Issues
**Symptoms**: Out of disk space or poor I/O performance
**Solutions**:
1. Increase EBS volume size
2. Optimize storage type (gp3, io1, io2)
3. Clean up unnecessary files
4. Monitor disk utilization

### Debugging Commands

```bash
# Check instance status
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# View instance console output
aws ec2 get-console-output --instance-id i-1234567890abcdef0

# Monitor instance metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-12345678

# Verify key pair
aws ec2 describe-key-pairs --key-names bongaquino-staging-key
```

## Environment-Specific Deployment

### Staging Environment
```bash
cd bongaquino-aws/ec2/envs/staging
terraform init
AWS_PROFILE=bongaquino terraform plan
AWS_PROFILE=bongaquino terraform apply
```

### Production Environment
```bash
cd bongaquino-aws/ec2/envs/prod
terraform init
AWS_PROFILE=bongaquino terraform plan
AWS_PROFILE=bongaquino terraform apply
```

## Best Practices

### Instance Management
1. **Use Latest AMIs**: Regularly update to latest patched AMIs
2. **Right-Size Instances**: Match instance type to workload requirements
3. **Enable Termination Protection**: Protect critical instances from accidental deletion
4. **Tag Consistently**: Use standardized tagging for cost allocation and management
5. **Monitor Performance**: Set up comprehensive CloudWatch monitoring

### Security
1. **Least Privilege Access**: Limit SSH access to specific IP ranges
2. **Regular Key Rotation**: Rotate SSH keys every 90 days
3. **Enable Encryption**: Use encrypted EBS volumes and enable encryption by default
4. **Patch Management**: Implement automated patching via SSM
5. **Network Segmentation**: Use security groups and NACLs effectively

### Operational
1. **Backup Strategy**: Implement automated backup with appropriate retention
2. **Disaster Recovery**: Plan for cross-region recovery scenarios
3. **Cost Monitoring**: Regular cost analysis and optimization
4. **Documentation**: Maintain up-to-date runbooks and procedures
5. **Testing**: Regular DR and backup restore testing

### Performance
1. **Instance Placement**: Use placement groups for low latency
2. **Storage Optimization**: Choose appropriate EBS volume types
3. **Network Optimization**: Utilize enhanced networking when available
4. **Monitoring**: Set up performance baselines and alerts
5. **Scaling**: Plan for both vertical and horizontal scaling

## Dependencies

- **VPC**: Virtual Private Cloud for network isolation
- **Security Groups**: Network access control
- **Key Pairs**: SSH access management
- **IAM**: Identity and access management
- **CloudWatch**: Monitoring and alerting
- **S3**: Backup storage and AMI management
- **SSM**: Patch management and automation

## Integration with Other Modules

- **VPC**: Network infrastructure and subnets
- **Security Groups**: Network access control rules
- **ALB**: Load balancing for multiple instances
- **RDS**: Database connectivity and security
- **CloudWatch**: Monitoring and logging integration
- **Backup**: Automated backup and recovery
- **IAM**: Role-based access control

## Maintenance

- **Patch Management**: Monthly security updates via SSM
- **Backup Verification**: Weekly backup restore testing
- **Performance Review**: Monthly performance and cost analysis
- **Security Audits**: Quarterly security configuration review
- **Capacity Planning**: Annual capacity and growth planning

## Support

For issues related to:
- **Configuration**: Review Terraform configuration and EC2 documentation
- **Performance**: Analyze CloudWatch metrics and instance sizing
- **Security**: Review security groups, key management, and access controls
- **Costs**: Monitor usage patterns and optimize instance types
- **Connectivity**: Troubleshoot network configuration and security rules 