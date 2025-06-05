# EC2 Module

This module manages EC2 instances and related resources for the Koneksi project.

## Directory Structure

```
ec2/
├── envs/                    # Environment-specific configurations
│   ├── staging/            # Staging environment
│   ├── uat/               # UAT environment
│   └── prod/              # Production environment
├── keys/                   # SSH key management
│   ├── backup/            # Key backups
│   └── README.md          # Key management documentation
├── scripts/               # Utility scripts
│   ├── rotate_keys.sh     # Key rotation script
│   └── manage_key_access.sh # Key access management script
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions
├── key_pair.tf           # Key pair management
├── backend.tf            # Backend configuration
└── README.md             # This file
```

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

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region | string | "ap-southeast-1" | no |
| environment | Deployment environment | string | - | yes |
| project | Project name | string | "koneksi" | no |
| instance_type | EC2 instance type | string | "t3a.micro" | no |
| vpc_id | VPC ID | string | - | yes |
| subnet_id | Subnet ID | string | - | yes |
| key_name | SSH key name | string | - | yes |
| allowed_cidr_blocks | Allowed CIDR blocks | list(string) | ["0.0.0.0/0"] | no |

## Outputs

| Name | Description |
|------|-------------|
| bastion_instance_id | ID of the bastion instance |
| bastion_public_ip | Public IP of the bastion instance |
| bastion_security_group_id | ID of the bastion security group |
| key_name | Name of the SSH key pair |

## Security

- SSH keys are managed through AWS Secrets Manager
- Regular key rotation (every 90 days)
- Environment-specific key pairs
- Access control through IAM
- Security group rules for bastion host

## Maintenance

1. Regular key rotation:
   ```bash
   ./scripts/rotate_keys.sh <environment>
   ```

2. Access management:
   ```bash
   ./scripts/manage_key_access.sh <environment> <action> [user/role]
   ```

3. State management:
   - State is stored in S3
   - State locking through DynamoDB
   - Regular state backups

## Contributing

1. Follow the naming conventions
2. Update documentation
3. Test changes in staging
4. Follow security best practices 