# Staging CD Pipeline Setup

This directory contains the Terraform configuration for setting up a Continuous Deployment pipeline that deploys the `bongaquino-backend` application from the `staging` branch to the existing EC2 instance at `52.77.36.120`.

## Overview

The CD pipeline consists of:
- **AWS CodePipeline**: Orchestrates the deployment process
- **AWS CodeBuild**: Executes the deployment script
- **GitHub Connection**: Connects to the GitHub repository
- **S3 Artifact Store**: Stores pipeline artifacts
- **Systems Manager Parameter Store**: Securely stores the SSH private key

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform** installed
3. **SSH private key** for the EC2 instance
4. **GitHub repository access** to `bongaquino-tech/bongaquino-backend`
5. **Existing EC2 instance** at `52.77.36.120` with:
   - `/home/ubuntu/bongaquino-backend` directory already set up
   - Docker and docker-compose installed
   - Git repository already cloned

## Setup Steps

### 1. Store SSH Private Key in Parameter Store

First, you need to store your SSH private key in AWS Systems Manager Parameter Store:

```bash
# Read your SSH key and store it in Parameter Store
aws ssm put-parameter \
  --name "/bongaquino/staging/ssh-key" \
  --type "SecureString" \
  --value "$(cat ~/Documents/bongaquino/bongaquino-staging-key.pem)" \
  --region ap-southeast-1
```

### 2. Run the Setup Script

```bash
cd bongaquino-aws/cd-setup/staging
chmod +x setup.sh
./setup.sh
```

### 3. Apply the Configuration

```bash
terraform apply
```

### 4. Connect GitHub Repository

After applying the Terraform configuration:

1. Go to the AWS Console → Developer Tools → Settings → Connections
2. Find the connection created by Terraform (name: `bongaquino-staging-github-connection`)
3. Click "Pending" and then "Connect"
4. Choose "GitHub" and click "Connect to GitHub"
5. Authorize AWS to access your GitHub account
6. Return to AWS and click "Connect" to complete the connection

### 5. Test the Pipeline

Once the GitHub connection is established, the pipeline will automatically trigger when changes are pushed to the `staging` branch.

## Pipeline Flow

1. **Source Stage**: Monitors the `staging` branch of `bongaquino-tech/bongaquino-backend`
2. **Deploy Stage**: 
   - Retrieves SSH key from Parameter Store
   - Connects to existing EC2 instance via SSH
   - Navigates to `/home/ubuntu/bongaquino-backend`
   - Pulls latest changes from staging branch
   - Builds the Go application
   - Restarts services using docker-compose (if available) or individual containers

## Manual Trigger

To manually trigger the pipeline:

```bash
# Using the trigger script
chmod +x trigger-deployment.sh
./trigger-deployment.sh

# Or using AWS CLI directly
aws codepipeline start-pipeline-execution \
  --name bongaquino-staging-deploy-pipeline \
  --region ap-southeast-1
```

## Monitoring

- **Pipeline Status**: AWS Console → Developer Tools → Pipelines
- **Build Logs**: AWS Console → Developer Tools → Build projects
- **CloudWatch Logs**: For detailed execution logs

## Troubleshooting

### SSH Connection Issues
- Verify the SSH key is correctly stored in Parameter Store
- Check that the EC2 instance is accessible from AWS CodeBuild
- Ensure the SSH user (`ubuntu`) has the correct permissions

### GitHub Connection Issues
- Verify the GitHub connection status in AWS Console
- Check that the repository and branch names are correct
- Ensure the GitHub account has access to the repository

### Build Failures
- Check the CodeBuild logs for detailed error messages
- Verify that the Go application builds successfully
- Ensure Docker is running on the EC2 instance
- Check that the `/home/ubuntu/bongaquino-backend` directory exists and contains the repository

### Deployment Issues
- Verify that docker-compose.yml exists in the repository (if using docker-compose)
- Check that the Docker network `bongaquino-network` exists
- Ensure the application is accessible on port 3000

## Security Considerations

- The SSH private key is stored encrypted in Parameter Store
- IAM roles have minimal required permissions
- The pipeline only accesses the specific GitHub repository and branch
- All resources are tagged for cost tracking and management

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Note**: This will also delete the S3 bucket with all artifacts. Make sure to backup any important data before running this command.

## Files Overview

- `main.tf`: Main Terraform configuration
- `variables.tf`: Variable definitions
- `outputs.tf`: Output values
- `buildspec.yml`: CodeBuild deployment script
- `setup.sh`: Automated setup script
- `trigger-deployment.sh`: Manual pipeline trigger script
- `README.md`: This documentation 