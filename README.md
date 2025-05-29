# Koneksi AWS Deployment

This repository contains the Terraform configurations for deploying Koneksi's AWS infrastructure.

## Infrastructure Components

- **IAM**: User and group management for ARData team
  - Test users for developers and devops
  - Group-based access control
  - Custom policies for different roles
  - Access key management

- **VPC**: Multi-AZ VPC with public, private, and data private subnets
  - Two availability zones
  - NAT Gateways for private subnet internet access
  - Internet Gateway for public subnet access
  - Security groups for controlled access

- **DynamoDB**: NoSQL database for data storage
  - Auto-scaling enabled
  - Point-in-time recovery
  - Encryption at rest

- **ElastiCache (Redis)**: In-memory data store for caching
  - Redis 7.1.0
  - Multi-AZ deployment
  - Automatic failover
  - Read replicas for scaling

- **EC2**: Bastion host for secure access
  - Ubuntu 24.04 LTS
  - t3.micro instance type
  - SSH access via key pair

## Directory Structure

```
koneksi-aws/
├── iam/             # IAM users, groups, and policies
├── vpc/             # VPC and networking configuration
├── dynamodb/        # DynamoDB table configuration
├── elasticache/     # ElastiCache Redis configuration
├── ec2/             # EC2 instance configuration
├── s3/              # S3 bucket for Terraform state
└── docs/            # Service documentation
    └── redis-service.md  # Redis service documentation
```

## Environment Support

The infrastructure supports multiple environments:
- Staging
- UAT
- Production

Each environment has its own:
- Terraform state file
- Variable configurations
- Resource naming conventions

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions
- Git for version control

## Usage

1. Initialize Terraform in each directory:
```bash
cd iam
terraform init
```

2. Apply the configurations in order:
```bash
# First, create IAM users and groups
cd iam
terraform apply

# Then, create the VPC
cd ../vpc
terraform apply

# Create DynamoDB
cd ../dynamodb
terraform apply

# Create ElastiCache
cd ../elasticache
terraform apply

# Finally, create EC2 instance
cd ../ec2
terraform apply
```

## Security

- IAM users and groups with least privilege access
- VPC is configured with public and private subnets
- Security groups are set up to allow necessary traffic
- SSH access is allowed from anywhere to public subnets
- Private subnets are accessible only from within the VPC
- All resources are tagged with environment and project name
- Encryption enabled for all applicable services

## Documentation

Detailed service documentation is available in the `docs` directory:
- [Redis Service Documentation](docs/redis-service.md)

## Maintenance

- Regularly review and update IAM permissions
- Always review and update the security groups as needed
- Monitor the NAT Gateway costs
- Regularly check for Terraform and provider updates
- Monitor service metrics and logs
- Keep documentation up to date

## Contributing

1. Create a new branch for your changes
2. Make your changes
3. Test the changes in staging
4. Create a pull request
5. Get approval from the team
6. Merge to staging first
7. After testing, merge to main

## Support

For any issues or questions, contact the DevOps team. 