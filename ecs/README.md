# Elastic Container Service (ECS) Module

This module provisions a fully managed ECS Fargate cluster with auto-scaling, comprehensive monitoring, and seamless integration with Application Load Balancers for the bongaquino infrastructure.

## Overview

The ECS module creates a production-ready containerized environment using AWS Fargate, eliminating the need to manage EC2 instances while providing scalable, secure, and monitored container deployment.

## Features

- **AWS Fargate**: Serverless container platform - no EC2 management required
- **Auto Scaling**: CPU and memory-based automatic scaling policies
- **Container Insights**: Enhanced monitoring and observability
- **ALB Integration**: Seamless integration with Application Load Balancers
- **IAM Security**: Least privilege access with dedicated task and execution roles
- **CloudWatch Logging**: Centralized log management with configurable retention
- **SSM Integration**: Secure parameter and secret management
- **ECR Integration**: Full support for private container registries
- **Deployment Circuit Breaker**: Automatic rollback on failed deployments
- **Health Checks**: Application-level health monitoring

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Application    │    │   ECS Cluster   │    │   CloudWatch    │
│  Load Balancer  │───▶│    (Fargate)    │───▶│     Logs        │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       ▲
         │                       ▼                       │
         │              ┌─────────────────┐              │
         │              │   ECS Service   │              │
         │              │  (Auto Scaling) │──────────────┘
         │              └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Target Group   │    │   ECS Tasks     │    │  Parameter      │
│   (Health       │◀───│   (Containers)  │───▶│    Store        │
│    Checks)      │    │                 │    │  (Secrets)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                               ▼
                       ┌─────────────────┐
                       │      ECR        │
                       │  (Container     │
                       │   Registry)     │
                       └─────────────────┘
```

## Directory Structure

```
ecs/
├── main.tf              # Main ECS configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── envs/                # Environment-specific configurations
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── uat/
│   └── prod/
└── README.md           # This documentation
```

## Resources Created

### Core ECS Resources
- **aws_ecs_cluster**: Fargate cluster with Container Insights enabled
- **aws_ecs_task_definition**: Container specification with networking and logging
- **aws_ecs_service**: Managed service with deployment and health management
- **aws_cloudwatch_log_group**: Centralized logging with configurable retention

### Auto Scaling Resources
- **aws_appautoscaling_target**: Scaling target configuration
- **aws_appautoscaling_policy**: CPU and memory-based scaling policies

### IAM Resources
- **aws_iam_role.ecs_task_execution_role**: Role for ECS to manage containers
- **aws_iam_role.ecs_task_role**: Role for application code within containers
- **aws_iam_policy**: Custom policies for SSM and CloudWatch access

## Usage

### Basic Configuration

```hcl
module "ecs" {
  source = "./ecs"
  
  # Basic settings
  project     = "bongaquino"
  environment = "staging"
  region      = "ap-southeast-1"
  
  # Network configuration
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  ecs_security_group_id = module.vpc.ecs_security_group_id
  
  # Container configuration
  container_image = "985869370256.dkr.ecr.ap-southeast-1.amazonaws.com/bongaquino-backend:latest"
  container_port  = 8080
  
  # ALB integration
  target_group_arn = module.alb.target_group_arn
  
  # Resource allocation
  task_cpu    = 512
  task_memory = 1024
  
  # Scaling configuration
  service_desired_count = 2
  max_capacity         = 10
  min_capacity         = 1
}
```

### Production Configuration with Secrets

```hcl
module "ecs" {
  source = "./ecs"
  
  # ... basic configuration ...
  
  # Environment variables
  container_environment = [
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "PORT"
      value = "8080"
    }
  ]
  
  # Secrets from Parameter Store
  container_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/bongaquino/staging/database-url"
    },
    {
      name      = "JWT_SECRET"
      valueFrom = "arn:aws:ssm:ap-southeast-1:985869370256:parameter/bongaquino/staging/jwt-secret"
    }
  ]
  
  # Performance tuning
  task_cpu    = 1024
  task_memory = 2048
  
  # Aggressive scaling
  cpu_utilization_target    = 60
  memory_utilization_target = 60
  scale_out_cooldown       = 180
  scale_in_cooldown        = 300
  
  # Extended log retention
  log_retention_days = 90
}
```

### Environment-Specific Deployment

1. **Navigate to ECS directory**:
```bash
cd bongaquino-aws/ecs
```

2. **Select environment workspace**:
```bash
terraform workspace select staging
```

3. **Initialize with environment backend**:
```bash
terraform init -backend-config=envs/staging/backend.tf
```

4. **Plan the deployment**:
```bash
AWS_PROFILE=bongaquino terraform plan -var-file=envs/staging/terraform.tfvars
```

5. **Apply the configuration**:
```bash
AWS_PROFILE=bongaquino terraform apply -var-file=envs/staging/terraform.tfvars
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project` | string | - | Project name for resource naming |
| `environment` | string | - | Environment name (staging/uat/prod) |
| `region` | string | `ap-southeast-1` | AWS region for deployment |
| `vpc_id` | string | - | VPC ID where ECS resources will be created |
| `private_subnet_ids` | list(string) | - | List of private subnet IDs for ECS tasks |
| `ecs_security_group_id` | string | - | Security group ID for ECS tasks |

### Container Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `container_image` | string | - | Container image URI (ECR recommended) |
| `container_port` | number | `80` | Port exposed by the container |
| `container_environment` | list(map(string)) | `[]` | Environment variables for container |
| `container_secrets` | list(map(string)) | `[]` | Secrets from Parameter Store/Secrets Manager |

### Resource Allocation
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `task_cpu` | number | `256` | CPU units (256 = 0.25 vCPU) |
| `task_memory` | number | `512` | Memory in MB |
| `service_desired_count` | number | `1` | Initial number of tasks |

### Auto Scaling Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `max_capacity` | number | `4` | Maximum number of tasks |
| `min_capacity` | number | `1` | Minimum number of tasks |
| `cpu_utilization_target` | number | `70` | Target CPU utilization % for scaling |
| `memory_utilization_target` | number | `70` | Target memory utilization % for scaling |
| `scale_in_cooldown` | number | `300` | Cooldown period for scale-in (seconds) |
| `scale_out_cooldown` | number | `300` | Cooldown period for scale-out (seconds) |

### Load Balancer Integration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `target_group_arn` | string | `null` | ARN of ALB target group for integration |
| `alb_security_group_id` | string | - | ALB security group for network rules |

### Logging Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_retention_days` | number | `30` | CloudWatch log retention period |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_id` | ECS cluster ID |
| `cluster_name` | ECS cluster name |
| `service_name` | ECS service name |
| `task_definition_arn` | Task definition ARN |
| `task_execution_role_arn` | Task execution role ARN |
| `task_role_arn` | Task role ARN |
| `log_group_name` | CloudWatch log group name |

## Container Configuration

### Environment Variables

Environment variables are passed directly to the container:

```hcl
container_environment = [
  {
    name  = "NODE_ENV"
    value = "production"
  },
  {
    name  = "DATABASE_HOST"
    value = "prod-database.internal"
  }
]
```

### Secrets Management

Secrets are retrieved from AWS Parameter Store or Secrets Manager:

```hcl
container_secrets = [
  {
    name      = "DATABASE_PASSWORD"
    valueFrom = "arn:aws:ssm:ap-southeast-1:account:parameter/bongaquino/prod/database-password"
  },
  {
    name      = "API_KEY"
    valueFrom = "arn:aws:secretsmanager:ap-southeast-1:account:secret:bongaquino/prod/api-key"
  }
]
```

## Auto Scaling Policies

### CPU-Based Scaling
- **Metric**: ECSServiceAverageCPUUtilization
- **Target**: 70% (configurable)
- **Scale Out**: When CPU > target for 2 consecutive periods
- **Scale In**: When CPU < target for 15 consecutive periods

### Memory-Based Scaling
- **Metric**: ECSServiceAverageMemoryUtilization
- **Target**: 70% (configurable)
- **Scale Out**: When memory > target for 2 consecutive periods
- **Scale In**: When memory < target for 15 consecutive periods

### Scaling Behavior
```
Tasks: 1 ────────▶ 2 ────────▶ 4 ────────▶ 10 (max)
       │           │           │           │
       │           │           │           ▼
       ▼           ▼           ▼     Scale-in cooldown
   Base load   Medium load  High load    (5 minutes)
                                           │
Scale-out cooldown (5 minutes)             ▼
                                      Gradual scale-in
```

## Security Features

### Network Security
- **Private Subnets**: Tasks run in private subnets only
- **Security Groups**: Controlled ingress/egress rules
- **No Public IP**: Tasks don't have direct internet access

### IAM Security
- **Task Execution Role**: Minimal permissions for ECS operations
- **Task Role**: Application-specific permissions
- **Least Privilege**: Only necessary permissions granted

### Secrets Management
- **Parameter Store**: Encrypted parameter storage
- **In-Transit Encryption**: All secrets encrypted during retrieval
- **At-Rest Encryption**: Parameters encrypted with KMS

## Monitoring & Logging

### Container Insights
Provides metrics for:
- CPU utilization
- Memory utilization
- Network I/O
- Storage I/O
- Task count

### CloudWatch Logs
- **Centralized Logging**: All container logs in CloudWatch
- **Structured Logging**: JSON-formatted logs recommended
- **Log Retention**: Configurable retention period
- **Log Streaming**: Real-time log viewing

### Health Checks
- **ALB Health Checks**: Application-level health monitoring
- **ECS Health Checks**: Container-level health monitoring
- **Circuit Breaker**: Automatic rollback on deployment failures

## Cost Optimization

### Resource Sizing
- **Right-sizing**: Monitor actual usage to optimize CPU/memory
- **Spot Fargate**: Consider for non-critical workloads (not yet configured)
- **Reserved Capacity**: For predictable workloads

### Auto Scaling
- **Efficient Scaling**: Prevents over-provisioning
- **Cooldown Periods**: Prevents rapid scaling events
- **Target Utilization**: Balances performance and cost

## Common CPU/Memory Configurations

| Workload Type | CPU | Memory | Use Case |
|---------------|-----|--------|----------|
| Micro Service | 256 | 512 MB | Simple APIs, low traffic |
| Web Application | 512 | 1024 MB | Standard web apps |
| API Gateway | 1024 | 2048 MB | High-traffic APIs |
| Background Jobs | 2048 | 4096 MB | Data processing |
| Database Proxy | 4096 | 8192 MB | High-performance proxy |

## Dependencies

- **VPC Module**: Provides network infrastructure
- **ALB Module**: For load balancing (optional)
- **ECR Repository**: For container images
- **Parameter Store**: For secrets and configuration
- **Security Groups**: For network access control

## Troubleshooting

### Service Not Starting
1. Check CloudWatch logs for container errors
2. Verify container image exists and is accessible
3. Validate environment variables and secrets
4. Check security group rules
5. Verify IAM role permissions

### Auto Scaling Issues
1. Monitor CloudWatch metrics for CPU/memory usage
2. Check scaling policies configuration
3. Verify cooldown periods
4. Review scaling history in AWS Console

### Load Balancer Integration
1. Verify target group health checks
2. Check security group rules between ALB and ECS
3. Validate container port configuration
4. Monitor ALB target health status

### Performance Issues
1. Monitor Container Insights metrics
2. Analyze CloudWatch logs for bottlenecks
3. Consider resource allocation adjustments
4. Review application performance profiling

## Best Practices

1. **Container Images**: Use multi-stage builds to minimize image size
2. **Health Checks**: Implement proper application health endpoints
3. **Logging**: Use structured logging (JSON) for better analysis
4. **Secrets**: Never embed secrets in container images
5. **Resource Limits**: Set appropriate CPU and memory limits
6. **Monitoring**: Set up CloudWatch alarms for key metrics
7. **Deployment**: Use blue-green or rolling deployments
8. **Security**: Regularly update container images for security patches

## Integration with Other Modules

- **ALB**: Load balancing and SSL termination
- **Route53**: DNS management for services
- **ACM**: SSL certificates for HTTPS endpoints
- **CloudWatch**: Monitoring and alerting
- **Parameter Store**: Configuration and secrets management
- **ECR**: Container image registry

## Maintenance

- **Image Updates**: Regularly update container images
- **Scaling Review**: Monitor and adjust scaling policies
- **Log Management**: Review and adjust log retention
- **Security Updates**: Keep ECS platform version updated
- **Cost Review**: Monitor and optimize resource allocation
- **Performance Tuning**: Regular performance analysis and optimization

## Support

For issues related to:
- **Container Startup**: Check CloudWatch logs and task definition
- **Scaling**: Review CloudWatch metrics and scaling policies
- **Connectivity**: Verify security groups and network configuration
- **Performance**: Analyze Container Insights and application metrics
- **Security**: Review IAM roles and secrets management