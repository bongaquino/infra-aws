# AWS CodePipeline Module

This module provisions comprehensive CI/CD pipelines using AWS CodePipeline, CodeBuild, and supporting infrastructure for automated application deployment across multiple environments and deployment targets (ECS Fargate and EC2).

## Overview

The CodePipeline module creates enterprise-grade continuous integration and deployment pipelines with support for multiple deployment strategies, automated testing, artifact management, and comprehensive monitoring. It integrates with GitHub for source control and supports both containerized (ECS) and traditional (EC2) deployment patterns.

## Features

- **Multi-Environment Support**: Separate pipelines for staging, UAT, and production
- **Dual Deployment Strategies**: ECS Fargate containers and EC2 server deployments
- **Automated CI/CD**: Complete source-to-deployment automation with GitHub integration
- **Artifact Management**: S3-based artifact storage with lifecycle policies
- **Security Best Practices**: IAM roles with least privilege, encrypted artifact storage
- **Docker Integration**: ECR repositories with image scanning and automated builds
- **Monitoring & Alerting**: CloudWatch integration with build status notifications
- **SSH Deployment**: Secure parameter store integration for EC2 deployments
- **Blue-Green Deployments**: Zero-downtime deployments for ECS services
- **Rollback Capabilities**: Automated and manual rollback mechanisms

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            GitHub Repository                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │  staging branch │  │   uat branch    │  │      main branch            │ │
│  └─────────┬───────┘  └─────────┬───────┘  └─────────────┬───────────────┘ │
└────────────┼────────────────────┼────────────────────────┼─────────────────┘
             │                    │                        │
             ▼                    ▼                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS CodePipeline Orchestration                      │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │ Staging Pipeline│  │  UAT Pipeline   │  │      Prod Pipeline          │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │  ┌─────────────────────────┐│ │
│  │ │   Source    │ │  │ │   Source    │ │  │  │        Source           ││ │
│  │ └─────┬───────┘ │  │ └─────┬───────┘ │  │  └─────────┬───────────────┘│ │
│  │       │         │  │       │         │  │            │                │ │
│  │ ┌─────▼───────┐ │  │ ┌─────▼───────┐ │  │  ┌─────────▼───────────────┐│ │
│  │ │    Build    │ │  │ │    Build    │ │  │  │        Build            ││ │
│  │ │   (SSH)     │ │  │ │  (Docker)   │ │  │  │      (Docker)           ││ │
│  │ └─────┬───────┘ │  │ └─────┬───────┘ │  │  └─────────┬───────────────┘│ │
│  │       │         │  │       │         │  │            │                │ │
│  │ ┌─────▼───────┐ │  │ ┌─────▼───────┐ │  │  ┌─────────▼───────────────┐│ │
│  │ │   Deploy    │ │  │ │   Deploy    │ │  │  │       Deploy           ││ │
│  │ │   (EC2)     │ │  │ │   (ECS)     │ │  │  │       (ECS)             ││ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │  └─────────────────────────┘│ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
             │                    │                        │
             ▼                    ▼                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Deployment Targets                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   EC2 Server    │  │  ECS Cluster    │  │      ECS Cluster            │ │
│  │                 │  │                 │  │                             │ │
│  │ • SSH Access    │  │ • Auto Scaling  │  │  • Auto Scaling             │ │
│  │ • Docker Mgmt   │  │ • Load Balancer │  │  • Load Balancer            │ │
│  │ • Health Checks │  │ • Health Checks │  │  • Health Checks            │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pipeline Types

#### 1. ECS Pipeline (UAT/Production)
- **Source**: GitHub repository monitoring
- **Build**: Docker image creation and ECR push
- **Deploy**: ECS service update with rolling deployment
- **Features**: Auto-scaling, load balancing, health checks

#### 2. EC2 Pipeline (Staging)
- **Source**: GitHub repository monitoring  
- **Deploy**: SSH-based deployment to EC2 instances
- **Features**: Direct server access, manual scaling, custom deployment scripts

## Directory Structure

```
codepipeline/
├── README.md                    # This documentation
├── use-connection-policy.json   # GitHub connection IAM policy
├── staging/                     # EC2-based deployment pipeline
│   ├── main.tf                 # Pipeline configuration
│   ├── buildspec.yml           # Build specification
│   ├── variables.tf            # Input variables
│   ├── backend.tf              # Backend configuration
│   ├── ssm-role.tf             # SSM parameter access
│   ├── discord_monitoring.tf   # Discord notifications
│   └── README.md               # Staging-specific documentation
├── uat/                        # ECS-based deployment pipeline
│   ├── main.tf                 # Pipeline configuration
│   ├── buildspec.yml           # Docker build specification
│   └── backend.tf              # Backend configuration
└── staging-ecs/                # Alternative ECS pipeline for staging
    └── (similar structure)
```

## Resources Created

### Core Pipeline Resources
- **aws_codepipeline**: Main CI/CD pipeline orchestration
- **aws_codebuild_project**: Build environment for compilation/containerization
- **aws_codestarconnections_connection**: GitHub repository integration
- **aws_s3_bucket**: Artifact storage with encryption and versioning
- **aws_ecr_repository**: Container image registry (ECS pipelines)

### Security & Access Control
- **aws_iam_role**: Service roles for CodePipeline and CodeBuild
- **aws_iam_policy**: Custom policies for resource access
- **aws_ssm_parameter**: Secure storage for SSH keys and secrets

### Monitoring & Notifications
- **aws_cloudwatch_log_group**: Build and deployment logs
- **aws_sns_topic**: Pipeline status notifications
- **Discord integration**: Real-time build status alerts

## Usage

### ECS Container Pipeline (UAT)

```hcl
# Deploy to UAT environment
cd koneksi-aws/codepipeline/uat

# Initialize Terraform
terraform init

# Apply the configuration
AWS_PROFILE=koneksi terraform apply

# Verify pipeline creation
aws codepipeline list-pipelines --region ap-southeast-1
```

### EC2 Server Pipeline (Staging)

```hcl
# First, store SSH key in Parameter Store
aws ssm put-parameter \
  --name "/koneksi/staging/ssh-key" \
  --type "SecureString" \
  --value "$(cat ~/path/to/ssh-key.pem)" \
  --region ap-southeast-1

# Deploy pipeline
cd koneksi-aws/codepipeline/staging
terraform init
AWS_PROFILE=koneksi terraform apply
```

### GitHub Connection Setup

1. **Navigate to AWS Console**:
   - Go to Developer Tools → Settings → Connections

2. **Complete Connection**:
   - Find your connection (status: "Pending")
   - Click "Update pending connection"
   - Authorize GitHub access
   - Select repositories to connect

3. **Test Pipeline**:
   ```bash
   # Manual trigger
   aws codepipeline start-pipeline-execution \
     --name koneksi-uat-backend-pipeline \
     --region ap-southeast-1
   ```

## Pipeline Configurations

### ECS Pipeline Buildspec (UAT)

```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      golang: 1.22
  pre_build:
    commands:
      - aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/koneksi-uat-backend
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
  build:
    commands:
      - cd server
      - go mod tidy
      - docker build -t $REPOSITORY_URI:$IMAGE_TAG .
  post_build:
    commands:
      - docker tag $REPOSITORY_URI:$IMAGE_TAG $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - docker push $REPOSITORY_URI:latest
      - printf '[{"name":"koneksi-uat-backend","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files:
    - imagedefinitions.json
```

### EC2 Pipeline Features (Staging)

- **SSH-based deployment** to existing EC2 instances
- **Parameter Store integration** for secure key management
- **Docker container management** with health checks
- **Git repository synchronization** with branch-specific deployments
- **Application restart** with graceful shutdown

## Input Variables

### Common Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | string | - | Environment name (staging/uat/prod) |
| `project_name` | string | `koneksi` | Project name for resource naming |
| `github_repo` | string | - | GitHub repository name |
| `github_branch` | string | - | Branch to monitor for changes |

### ECS Pipeline Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_name` | string | - | ECS cluster name for deployment |
| `service_name` | string | - | ECS service name for deployment |
| `ecr_repository_name` | string | - | ECR repository for container images |

### EC2 Pipeline Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ec2_instance_ip` | string | - | Target EC2 instance IP address |
| `ssh_key_parameter` | string | - | SSM parameter name for SSH key |
| `deployment_path` | string | `/home/ubuntu` | Application deployment path |

### Notification Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `discord_webhook_url` | string | `""` | Discord webhook for notifications |
| `enable_notifications` | bool | `true` | Enable build status notifications |

## Outputs

| Output | Description |
|--------|-------------|
| `pipeline_name` | Name of the created CodePipeline |
| `pipeline_arn` | ARN of the CodePipeline |
| `codebuild_project_name` | Name of the CodeBuild project |
| `artifact_bucket_name` | S3 bucket name for pipeline artifacts |
| `ecr_repository_url` | ECR repository URL (ECS pipelines only) |
| `github_connection_arn` | GitHub connection ARN |
| `pipeline_role_arn` | IAM role ARN for the pipeline |

## Security Features

### IAM Security
- **Least Privilege Access**: Minimal required permissions for each role
- **Service-Specific Roles**: Separate roles for CodePipeline and CodeBuild
- **Resource-Scoped Policies**: Access limited to specific resources

### Secret Management
- **AWS Systems Manager**: Secure parameter store for SSH keys
- **Encryption at Rest**: All secrets encrypted with AWS KMS
- **No Hardcoded Credentials**: All sensitive data stored securely

### Network Security
- **VPC Integration**: CodeBuild projects can run in private subnets
- **Security Group Controls**: Network access controls for build environments
- **SSH Key Rotation**: Regular rotation of deployment keys

## Monitoring & Alerting

### CloudWatch Integration
```hcl
# Pipeline state monitoring
resource "aws_cloudwatch_event_rule" "pipeline_state_change" {
  name = "pipeline-state-change"
  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.backend_pipeline.name]
    }
  })
}
```

### Discord Notifications
- **Build Status Updates**: Real-time build success/failure notifications
- **Deployment Alerts**: Deployment completion and status updates
- **Error Reporting**: Detailed error information for failed builds

### Log Management
- **CloudWatch Logs**: Centralized logging for build and deployment processes
- **Log Retention**: Configurable retention periods for cost optimization
- **Log Analysis**: CloudWatch Insights for troubleshooting

## Performance Optimization

### Build Performance
- **Docker Layer Caching**: Optimized Dockerfile for faster builds
- **Parallel Builds**: Multiple concurrent build processes
- **Artifact Caching**: Build artifact caching for faster deployments

### Deployment Performance
- **Rolling Deployments**: Zero-downtime deployments for ECS
- **Health Checks**: Automated health verification before traffic switching
- **Rollback Mechanisms**: Quick rollback on deployment failures

## Cost Management

### Resource Optimization
- **Build Instance Sizing**: Right-sized CodeBuild environments
- **Artifact Lifecycle**: S3 lifecycle policies for artifact cleanup
- **Reserved Capacity**: Optional reserved build capacity for consistent workloads

### Cost Monitoring
```hcl
# Cost allocation tags
tags = {
  Project     = "koneksi"
  Environment = var.environment
  CostCenter  = "engineering"
  Owner       = "devops-team"
}
```

## Troubleshooting

### Common Issues

#### GitHub Connection Failed
```
Error: GitHub connection not authorized
```
**Solution**:
1. Check connection status in AWS Console
2. Re-authorize GitHub access
3. Verify repository permissions

#### Build Failures
```
Error: Docker build failed
```
**Solution**:
1. Check CodeBuild logs in CloudWatch
2. Verify Dockerfile syntax
3. Check build environment permissions

#### ECS Deployment Timeout
```
Error: ECS deployment timed out
```
**Solution**:
1. Check ECS service health checks
2. Verify target group health
3. Review application startup logs

#### SSH Connection Issues (EC2 Pipeline)
```
Error: SSH connection refused
```
**Solution**:
1. Verify SSH key in Parameter Store
2. Check EC2 instance accessibility
3. Validate security group rules

### Debugging Commands

```bash
# Check pipeline status
aws codepipeline get-pipeline-state \
  --name koneksi-uat-backend-pipeline

# View build logs
aws logs describe-log-streams \
  --log-group-name /aws/codebuild/koneksi-uat-backend-build

# Check ECS deployment status
aws ecs describe-services \
  --cluster koneksi-uat-cluster \
  --services koneksi-uat-service

# Test GitHub connection
aws codestar-connections list-connections \
  --provider-type GitHub

# Monitor pipeline execution
aws codepipeline list-pipeline-executions \
  --pipeline-name koneksi-uat-backend-pipeline
```

## Best Practices

### Pipeline Design
1. **Environment Separation**: Separate pipelines for each environment
2. **Branch Strategy**: Use GitFlow or similar branching strategy
3. **Automated Testing**: Include automated tests in build process
4. **Security Scanning**: Integrate security scanning tools
5. **Documentation**: Maintain up-to-date pipeline documentation

### Deployment Strategy
1. **Blue-Green Deployments**: Use for zero-downtime deployments
2. **Health Checks**: Implement comprehensive health monitoring
3. **Rollback Plans**: Always have rollback procedures ready
4. **Monitoring**: Monitor application metrics post-deployment
5. **Gradual Rollouts**: Use canary deployments for critical changes

### Security
1. **Least Privilege**: Minimal IAM permissions for all roles
2. **Secret Rotation**: Regular rotation of deployment credentials
3. **Audit Logging**: Enable comprehensive audit logging
4. **Vulnerability Scanning**: Regular security scans of containers
5. **Access Control**: Strict access controls for pipeline modification

## Dependencies

- **GitHub**: Source code repository
- **S3**: Artifact storage and backend state
- **ECR**: Container image registry (ECS pipelines)
- **ECS**: Container orchestration (ECS pipelines)
- **EC2**: Target servers (EC2 pipelines)
- **Systems Manager**: Parameter store for secrets
- **CloudWatch**: Logging and monitoring
- **IAM**: Access control and permissions

## Integration with Other Modules

- **ECS**: Container deployment target
- **EC2**: Server deployment target
- **VPC**: Network infrastructure for build environment
- **ALB**: Load balancing for deployed applications
- **Route53**: DNS management for deployed services
- **CloudWatch**: Monitoring and alerting
- **S3**: Artifact storage and state management

## Maintenance

- **Regular Updates**: Keep build tools and dependencies current
- **Security Reviews**: Regular security audits and updates
- **Performance Monitoring**: Monitor build and deployment performance
- **Cost Optimization**: Regular cost analysis and optimization
- **Documentation**: Keep pipeline documentation synchronized

## Support

For issues related to:
- **Pipeline Configuration**: Review Terraform configuration and AWS documentation
- **Build Failures**: Check CodeBuild logs and build specifications
- **Deployment Issues**: Verify target environment health and configuration
- **GitHub Integration**: Check connection status and repository permissions
- **Performance**: Analyze build times and optimize configurations