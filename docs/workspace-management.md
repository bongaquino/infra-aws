# Terraform Workspace Management

This document describes how to manage different environments using Terraform workspaces in the Koneksi AWS infrastructure.

## Overview

Each module in the infrastructure uses Terraform workspaces to manage environment-specific resources. This allows us to maintain separate states and configurations for different environments while using the same codebase.

## Available Workspaces

- `staging`: Development and testing environment
- `uat`: User acceptance testing environment
- `prod`: Production environment

## Directory Structure

Each module follows this structure for environment-specific configurations:

```
module/
├── backend.tf              # Root backend config with dynamic key
├── envs/
│   ├── staging/
│   │   ├── backend.tf      # Environment-specific backend config (static values, no key)
│   │   └── terraform.tfvars # Environment-specific variables
│   ├── uat/
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.tf
│       └── terraform.tfvars
├── main.tf
├── variables.tf
└── outputs.tf
```

## Backend Configuration

### Root backend.tf Example
The root `backend.tf` in each module contains the dynamic key using the workspace variable:

```hcl
terraform {
  backend "s3" {
    bucket         = "placeholder"           # Overridden by envs/<env>/backend.tf
    key            = "<module>/${terraform.workspace}/terraform.tfstate"
    region         = "placeholder"           # Overridden by envs/<env>/backend.tf
    encrypt        = true
    dynamodb_table = "placeholder"           # Overridden by envs/<env>/backend.tf
  }
}
```

### Environment-Specific backend.tf Example
The `envs/<environment>/backend.tf` file contains only static values (no key):

```hcl
bucket         = "koneksi-terraform-state"
region         = "ap-southeast-1"
encrypt        = true
dynamodb_table = "koneksi-terraform-locks"
```

> **Note:** Do not include the `key` or any variable interpolation in the environment-specific backend config files. The dynamic key is handled in the root `backend.tf`.

## State Management

### State File Structure
State files are organized by module and workspace:
```
s3://koneksi-terraform-state/
├── vpc/
│   └── staging/terraform.tfstate
│   └── uat/terraform.tfstate
│   └── prod/terraform.tfstate
├── ec2/
│   └── staging/terraform.tfstate
│   └── uat/terraform.tfstate
│   └── prod/terraform.tfstate
└── ...
```

### State Locking
- State locking is enabled using DynamoDB: `koneksi-terraform-locks`
- Prevents concurrent modifications to the same state file
- Automatically releases locks after operations complete

## Using Workspaces

### 1. Select the Workspace
```bash
# List available workspaces
terraform workspace list

# Select the appropriate workspace
terraform workspace select staging|uat|prod
```

### 2. Initialize with Environment Configuration
```bash
# Initialize Terraform with environment-specific backend
terraform init -backend-config=envs/<environment>/backend.tf
```

### 3. Apply Changes
```bash
# Plan changes
terraform plan

# Apply changes
terraform apply
```

## Switching Between Modules and Environments

### Switching Modules
To switch to a different module, use the following commands:

```bash
# Navigate to the desired module directory
cd ../<module_name>  # e.g., cd ../ec2, cd ../dynamodb, etc.

# List available workspaces in the new module
terraform workspace list

# Select the appropriate workspace
terraform workspace select <workspace_name>  # e.g., staging, uat, or prod

# Initialize with the environment-specific backend
terraform init -backend-config=envs/<environment>/backend.tf

# Verify the current workspace and module
terraform workspace show
pwd  # to confirm current module directory
```

### Switching Environments
To switch environments within the same module:

```bash
# List current workspaces
terraform workspace list

# Switch to the desired environment
terraform workspace select <environment>  # e.g., staging, uat, or prod

# Reinitialize with the new environment's backend
terraform init -backend-config=envs/<environment>/backend.tf

# Verify the current environment
terraform workspace show
```

### Quick Reference Commands

#### Module Navigation
```bash
# List all modules
ls -d */

# Navigate to a specific module
cd <module_name>

# Return to root directory
cd ..
```

#### Environment Management
```bash
# List all environments in current module
ls envs/

# View environment-specific variables
cat envs/<environment>/terraform.tfvars

# View environment-specific backend config
cat envs/<environment>/backend.tf
```

#### State Management
```bash
# View current state
terraform state list

# Pull latest state
terraform init -reconfigure

# Verify state file location
terraform show
```

## Common Scenarios

#### Scenario 1: Switching from EC2 Staging to EC2 Production
```bash
# Ensure you're in the EC2 module
cd ec2

# Switch to production workspace
terraform workspace select prod

# Reinitialize with production backend
terraform init -backend-config=envs/prod/backend.tf

# Verify the switch
terraform workspace show
```

#### Scenario 2: Moving from EC2 to DynamoDB in Same Environment
```bash
# Navigate to DynamoDB module
cd ../dynamodb

# Select the same environment workspace
terraform workspace select staging  # or uat, or prod

# Initialize with environment-specific backend
terraform init -backend-config=envs/staging/backend.tf

# Verify the setup
terraform workspace show
```

#### Scenario 3: Checking All Module States
```bash
# Create a script to check all modules
for module in ec2 dynamodb elasticache iam route53 amplify cloudfront acm; do
    echo "Checking $module module..."
    cd $module
    terraform workspace show
    cd ..
done
```

## Environment-Specific Configurations

### Backend Configuration (backend.tf)
```hcl
terraform {
  backend "s3" {
    bucket         = "koneksi-terraform-state"
    key            = "module-name/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "koneksi-terraform-locks"
    encrypt        = true
  }
}
```

### Variable Configuration (terraform.tfvars)
```hcl
environment = "staging|uat|prod"
region      = "ap-southeast-1"
# Environment-specific variables
```

## Best Practices

1. **Always Check Current Context**
   - Check current module: `pwd`
   - Check current workspace: `terraform workspace show`
   - Check current state: `terraform state list`

2. **State Management**
   - Always pull latest state when switching: `terraform init -reconfigure`
   - Verify state file location matches environment
   - Check for any pending changes before switching

3. **Environment Variables**
   - Ensure correct AWS profile is set
   - Verify environment-specific variables are loaded
   - Check backend configuration matches environment

4. **Safety Checks**
   - Review planned changes before applying
   - Verify correct environment in AWS console
   - Check resource naming conventions

5. **Use Consistent Naming**
   - Resources should include environment name
   - Use consistent tags across environments

6. **Security**
   - Use appropriate IAM roles for each environment
   - Implement least privilege access
   - Enable encryption for state files

## Troubleshooting

### Common Issues

1. **Workspace Not Found**
   ```bash
   # Create new workspace if needed
   terraform workspace new staging|uat|prod
   ```

2. **State Lock Issues**
   ```bash
   # Force unlock if needed (use with caution)
   terraform force-unlock <lock-id>
   ```

3. **Backend Configuration Errors**
   - Verify S3 bucket exists
   - Check DynamoDB table exists
   - Ensure IAM permissions are correct

### Getting Help

For workspace-related issues:
1. Check the current workspace: `terraform workspace show`
2. Verify backend configuration: `terraform init -reconfigure`
3. Check state file: `terraform state list`
4. Contact DevOps team if issues persist

## Module-Specific Notes

### VPC Module
- Each environment has its own VPC
- Subnet CIDR ranges vary by environment
- Security groups are environment-specific

### EC2 Module
- Instance types may vary by environment
- Key pairs are environment-specific
- Security groups are environment-specific

### DynamoDB Module
- Table names include environment prefix
- Capacity units may vary by environment
- Backup retention varies by environment

### ElastiCache Module
- Cluster names include environment prefix
- Node types may vary by environment
- Security groups are environment-specific

## Maintenance

### Regular Tasks
1. Review workspace usage
2. Clean up unused workspaces
3. Verify state file integrity
4. Update environment configurations
5. Rotate access keys and certificates

### Monitoring
1. Check state file sizes
2. Monitor DynamoDB capacity
3. Review S3 bucket usage
4. Audit IAM permissions
5. Check resource tagging 