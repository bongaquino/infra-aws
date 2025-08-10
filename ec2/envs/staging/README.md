# EC2 Staging Environment

This directory contains the Terraform configuration for the EC2 instances in the staging environment.

## Resources Created

- Bastion Host
  - EC2 instance (t3a.micro)
  - Security group allowing SSH access from anywhere
  - Public IP address
  - Ubuntu 22.04 LTS AMI

- Backend Host
  - EC2 instance (t3a.micro)
  - Security group allowing access only from bastion host
  - Docker pre-installed
  - Ubuntu 22.04 LTS AMI

## Prerequisites

1. AWS credentials configured
2. VPC and subnet already created
3. SSH key pair generated

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Update variables:
   ```bash
   ./scripts/update_vars.sh staging
   ```

3. Plan changes:
   ```bash
   terraform plan
   ```

4. Apply changes:
   ```bash
   terraform apply
   ```

## Accessing Instances

After applying the configuration, you can access the instances using the following commands:

1. Bastion Host:
   ```bash
   ssh -i <key_name> ubuntu@<bastion_public_ip>
   ```

2. Backend Host (through bastion):
   ```bash
   ssh -i <key_name> -o ProxyCommand='ssh -i <key_name> -W %h:%p ubuntu@<bastion_public_ip>' ubuntu@<backend_private_ip>
   ```

## Variables

- `aws_region`: AWS region (default: ap-southeast-1)
- `environment`: Environment name (default: staging)
- `project`: Project name (default: bongaquino)
- `instance_type`: EC2 instance type (default: t3a.micro)
- `ami_id`: AMI ID for EC2 instances
- `vpc_id`: VPC ID
- `subnet_id`: Subnet ID
- `key_name`: SSH key name
- `allowed_cidr_blocks`: Allowed CIDR blocks for SSH access

## Outputs

- `bastion_ssh_command`: SSH command to connect to bastion
- `backend_ssh_command`: SSH command to connect to backend through bastion
- `bastion_public_dns`: Public DNS of bastion
- `backend_private_dns`: Private DNS of backend 