# AWS Deployment

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
  - Simplified security groups for controlled access
  - VPC endpoints for AWS services

- **DynamoDB**: NoSQL database for data storage
  - Auto-scaling enabled
  - Point-in-time recovery
  - Encryption at rest
  - VPC endpoint for private access

- **ElastiCache (Redis)**: In-memory data store for caching
  - Redis 7.1.0
  - Multi-AZ deployment
  - Automatic failover
  - Read replicas for scaling
  - Dedicated subnet group
  - Security group integration

- **EC2**: Application servers
  - Ubuntu 24.04 LTS
  - t3a.medium instance type
  - SSH access via key pair
  - Private subnet placement
  - Private security group

- **Amplify**: Web application hosting
  - Automatic CI/CD from GitHub
  - Built-in CloudFront distribution
  - SSL/TLS certificate management
  - Custom domain support
  - Branch-based deployments

- **Route53**: DNS management
  - Domain registration and management
  - DNS record management
  - Health checks
  - Traffic routing

- **ACM**: SSL/TLS Certificate Management
  - Certificate provisioning
  - Automatic renewal
  - Multi-region support
  - Domain validation

## Directory Structure

```
koneksi-aws/
├── acm/             # AWS Certificate Manager for SSL/TLS certificates
├── amplify/         # AWS Amplify for web app hosting
├── cloudfront/      # CloudFront CDN configuration
├── dynamodb/        # DynamoDB table configuration
├── ec2/            # EC2 instance configuration
├── elasticache/    # ElastiCache Redis configuration
├── iam/            # IAM users, groups, and policies
├── route53/        # DNS and domain management
├── s3/             # S3 bucket for Terraform state
├── vpc/            # VPC and networking configuration
└── docs/           # Service documentation
    ├── redis-service.md  # Redis service documentation
    └── workspace-management.md  # Workspace management documentation
```

## Module Dependencies

The modules should be applied in the following order:

1. **S3**: Terraform state bucket
2. **IAM**: User and group management
3. **ACM**: SSL/TLS certificates
4. **VPC**: Network infrastructure
5. **DynamoDB**: Database tables
6. **ElastiCache**: Redis cache
7. **EC2**: Compute instances
8. **Amplify**: Web application hosting
9. **Route53**: DNS management

## Environment Support

The infrastructure supports multiple environments through Terraform workspaces:
- `staging`: Development and testing environment
- `uat`: User acceptance testing environment
- `prod`: Production environment

Each environment has its own:
- Terraform state file
- Variable configurations
- Resource naming conventions
- Amplify branch and domain
- VPC resources (subnets, security groups, etc.)

For detailed information about managing environments using Terraform workspaces, see [Workspace Management Documentation](docs/workspace-management.md).

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions
- Git for version control
- Domain registered in Route53 (for custom domains)

## AWS Quotas and Limits

### Required Quotas
- **Elastic IPs (EIPs)**: 5 per environment (15 total for all environments)
  - 2 EIPs for NAT Gateways per environment
  - Additional EIPs for other resources as needed
- **VPCs**: 5 per region
- **NAT Gateways**: 2 per environment
- **Internet Gateways**: 1 per VPC

### Requesting Quota Increases
1. Go to AWS Service Quotas console: https://console.aws.amazon.com/servicequotas/
2. Select the region (ap-southeast-1)
3. Search for the service quota you need to increase
4. Click "Request quota increase"
5. Provide justification for the increase
6. Submit the request

### Common Quota Requirements
- EIPs: Request at least 5 per environment
- VPCs: Default limit is usually sufficient
- NAT Gateways: Default limit is usually sufficient

## State Management

### State File Structure
- Each module has its own state file
- State files are stored in S3
- State locking is enabled using DynamoDB
- Environment-specific states are separated

### State File Location
```
s3://koneksi-terraform-state/
├── vpc/
│   └── terraform.tfstate.d/
│       ├── staging/
│       ├── uat/
│       └── prod/
├── ec2/
│   └── terraform.tfstate.d/
│       ├── staging/
│       ├── uat/
│       └── prod/
└── ...
```

### State File Migration
1. Initialize the new backend:
```bash
terraform init -migrate-state
```

2. Verify the state:
```bash
terraform state list
```

3. Remove the old state file:
```bash
rm terraform.tfstate
```

## Environment Variables

### Required Environment Variables
```bash
export AWS_PROFILE=koneksi
export TF_VAR_environment=staging|uat|prod
export TF_VAR_region=ap-southeast-1
```

### AWS Profile Configuration
```ini
[profile koneksi]
region = ap-southeast-1
output = json
```

## Usage

1. Select the appropriate workspace:
```bash
terraform workspace select staging|uat|prod
```

2. Initialize Terraform with environment-specific backend:
```bash
terraform init -backend-config=envs/<environment>/backend.tf
```

3. Apply the configurations in order:
```bash
# First, create S3 bucket for state
cd s3
terraform apply

# Create IAM users and groups
cd ../iam
terraform apply

# Create ACM certificates
cd ../acm
terraform apply

# Create the VPC
cd ../vpc
terraform apply

# Create DynamoDB
cd ../dynamodb
terraform apply

# Create ElastiCache
cd ../elasticache
terraform apply

# Create EC2 instance
cd ../ec2
terraform apply

# Set up Amplify
cd ../amplify
terraform apply

# Finally, configure DNS
cd ../route53
terraform apply
```

## VPC Integration

### Subnet Usage
- **Public Subnets**: Resources requiring direct internet access
- **Private Subnets**: Application servers and internal resources
- **Data Private Subnets**: Database and cache resources

### Security Groups
- **Public SG**: For resources in public subnets
- **Private SG**: For resources in private subnets
- **Data Private SG**: For resources in data private subnets

### VPC Endpoints
- S3 Gateway endpoint
- DynamoDB Gateway endpoint
- SSM Interface endpoint
- Secrets Manager Interface endpoint

## Security

- IAM users and groups with least privilege access
- VPC is configured with public and private subnets
- Security groups are set up to allow necessary traffic
- Private subnets are accessible only from within the VPC
- All resources are tagged with environment and project name
- Encryption enabled for all applicable services
- SSL/TLS certificates managed by AWS Certificate Manager
- CloudFront distribution with HTTPS enforcement

## Documentation

Detailed service documentation is available in the `docs` directory:
- [Redis Service Documentation](docs/redis-service.md)
- [Workspace Management Documentation](docs/workspace-management.md)

## Maintenance

- Regularly review and update IAM permissions
- Always review and update the security groups as needed
- Monitor the NAT Gateway costs
- Regularly check for Terraform and provider updates
- Monitor service metrics and logs
- Keep documentation up to date
- Monitor SSL certificate expiration
- Check Amplify build status and logs
- Review CloudFront distribution metrics
- Monitor AWS quota usage
- Regularly check state file integrity

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
