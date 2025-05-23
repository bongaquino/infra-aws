# Koneksi AWS Deployment

This repository contains the Terraform configurations for deploying Koneksi's AWS infrastructure.

## Infrastructure Components

- VPC with public and private subnets across two availability zones
- DynamoDB for data storage
- ElastiCache (Redis) for caching

## Directory Structure

```
koneksi-aws-deployment/
├── vpc/              # VPC and networking configuration
├── dynamodb/         # DynamoDB table configuration
└── elasticache/      # ElastiCache Redis configuration
```

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions

## Usage

1. Initialize Terraform in each directory:
```bash
cd vpc
terraform init
```

2. Apply the configurations in order:
```bash
# First, create the VPC
cd vpc
terraform apply

# Then, create DynamoDB
cd ../dynamodb
terraform apply

# Finally, create ElastiCache
cd ../elasticache
terraform apply
```

## Security

- The VPC is configured with public and private subnets
- Security groups are set up to allow necessary traffic
- SSH access is allowed from anywhere to public subnets
- Private subnets are accessible only from within the VPC

## Maintenance

- Always review and update the security groups as needed
- Monitor the NAT Gateway costs
- Regularly check for Terraform and provider updates 