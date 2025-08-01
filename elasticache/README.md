# ElastiCache Redis Module

This module provisions a highly available, secure, and monitored Redis cluster using AWS ElastiCache for caching and session management in the Koneksi infrastructure.

## Overview

The ElastiCache module creates a production-ready Redis replication group with automatic failover, encryption at rest and in transit, and comprehensive monitoring. It's designed to provide fast, reliable caching and session storage for high-performance applications.

## Features

- **Redis 7.x**: Latest Redis engine with enhanced performance
- **Multi-AZ Deployment**: Automatic failover across availability zones
- **Encryption**: At-rest and in-transit encryption for security
- **Read Replicas**: Multiple read replicas for improved performance
- **Parameter Groups**: Optimized Redis configuration
- **CloudWatch Monitoring**: CPU and memory utilization alarms
- **Subnet Groups**: Dedicated subnet isolation
- **Backup & Restore**: Automated snapshots with configurable windows
- **Maintenance Windows**: Scheduled maintenance with minimal disruption

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Primary       │    │   CloudWatch    │
│   (ECS/EC2)     │───▶│   Redis Node    │───▶│   Monitoring    │
│                 │    │   (Write)       │    │   & Alarms      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       ▼
         │              ┌─────────────────┐
         │              │   Read Replica  │
         └─────────────▶│   Redis Nodes   │
                        │   (Read-only)   │
                        └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Subnet Group  │
                       │  (Data Private  │
                       │    Subnets)     │
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Security Group │
                       │   (Port 6379)   │
                       └─────────────────┘
```

## Directory Structure

```
elasticache/
├── main.tf              # Main ElastiCache configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── envs/                # Environment-specific configurations
│   ├── staging/
│   ├── uat/
│   └── prod/
└── README.md           # This documentation
```

## Resources Created

### Core ElastiCache Resources
- **aws_elasticache_replication_group**: Redis cluster with failover
- **aws_elasticache_subnet_group**: Dedicated subnet group for isolation
- **aws_elasticache_parameter_group**: Optimized Redis configuration

### Monitoring Resources
- **aws_cloudwatch_metric_alarm**: CPU and memory utilization monitoring

## Usage

### Basic Configuration

```hcl
module "elasticache" {
  source = "./elasticache"
  
  # Basic settings
  name_prefix  = "koneksi-staging"
  project      = "koneksi"
  environment  = "staging"
  aws_region   = "ap-southeast-1"
  
  # Network configuration
  vpc_id                  = module.vpc.vpc_id
  elasticache_subnet_ids  = module.vpc.data_private_subnet_ids
  vpc_security_group_id   = module.vpc.data_private_security_group_id
  
  # Redis configuration
  node_type              = "cache.t3.micro"
  number_cache_clusters  = 2
  
  # Security
  automatic_failover_enabled = true
}
```

### Production Configuration

```hcl
module "elasticache" {
  source = "./elasticache"
  
  # ... basic configuration ...
  
  # High-performance setup
  node_type              = "cache.r6g.large"
  number_cache_clusters  = 3
  
  # Custom parameter group
  parameter_group_parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    },
    {
      name  = "tcp-keepalive"
      value = "60"
    }
  ]
  
  # Maintenance and backup
  maintenance_window = "sun:03:00-sun:05:00"
  snapshot_window    = "01:00-03:00"
  
  # Encryption
  kms_key_id = "arn:aws:kms:ap-southeast-1:account:key/key-id"
  
  # Additional tags
  tags = {
    Backup      = "required"
    Compliance  = "required"
    CostCenter  = "engineering"
  }
}
```

### Environment-Specific Deployment

1. **Navigate to ElastiCache directory**:
```bash
cd koneksi-aws/elasticache
```

2. **Initialize Terraform**:
```bash
terraform init -backend-config=envs/staging/backend.tf
```

3. **Plan the deployment**:
```bash
AWS_PROFILE=koneksi terraform plan -var-file=envs/staging/terraform.tfvars
```

4. **Apply the configuration**:
```bash
AWS_PROFILE=koneksi terraform apply -var-file=envs/staging/terraform.tfvars
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name_prefix` | string | - | Prefix for resource names |
| `project` | string | `koneksi` | Project name for tagging |
| `environment` | string | `staging` | Environment name for tagging |
| `aws_region` | string | `ap-southeast-1` | AWS region for deployment |

### Network Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_id` | string | - | VPC ID where ElastiCache will be created |
| `elasticache_subnet_ids` | list(string) | - | List of subnet IDs for ElastiCache (data private subnets) |
| `vpc_security_group_id` | string | - | Security group ID for ElastiCache access |

### Redis Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `node_type` | string | `cache.t3.micro` | Instance type for Redis nodes |
| `number_cache_clusters` | number | `2` | Number of cache clusters (replicas) |
| `port` | number | `6379` | Redis port number |
| `parameter_group_name` | string | `default.redis7` | Parameter group name |
| `automatic_failover_enabled` | bool | `true` | Enable automatic failover |

### Security & Encryption
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `kms_key_id` | string | `null` | KMS key ID for encryption (uses default if null) |

### Backup & Maintenance
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `maintenance_window` | string | `sun:05:00-sun:09:00` | Weekly maintenance window |
| `snapshot_window` | string | `03:00-05:00` | Daily snapshot window |

### Parameter Group Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `parameter_group_parameters` | list(object) | `[{name="maxmemory-policy", value="allkeys-lru"}]` | Redis parameters |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `primary_endpoint_address` | Primary Redis endpoint for write operations |
| `reader_endpoint_address` | Reader endpoint for read operations |

## Redis Configuration Parameters

### Memory Management
- **maxmemory-policy**: `allkeys-lru` - Evict least recently used keys when memory limit reached
- **maxmemory**: Automatically set based on node type

### Connection Management
- **timeout**: Connection timeout in seconds
- **tcp-keepalive**: TCP keepalive interval
- **tcp-backlog**: TCP listen backlog size

### Performance Tuning
- **save**: Disable disk persistence for performance (data in memory only)
- **appendonly**: Enable/disable append-only file logging
- **lazy-freeing**: Enable non-blocking key deletion

## Node Type Recommendations

| Environment | Node Type | Memory | vCPUs | Use Case |
|-------------|-----------|--------|-------|----------|
| Development | cache.t3.micro | 512 MB | 2 | Development/testing |
| Staging | cache.t3.small | 1.37 GB | 2 | Light staging workloads |
| Production (Small) | cache.r6g.large | 12.3 GB | 2 | Small production workloads |
| Production (Medium) | cache.r6g.xlarge | 25.05 GB | 4 | Medium production workloads |
| Production (Large) | cache.r6g.2xlarge | 50.47 GB | 8 | Large production workloads |

## Security Features

### Encryption
- **At-Rest Encryption**: All data encrypted using AWS KMS
- **In-Transit Encryption**: TLS encryption for all connections
- **Key Management**: Customer-managed or AWS-managed KMS keys

### Network Security
- **VPC Isolation**: Redis cluster deployed in private subnets
- **Security Groups**: Controlled access via security group rules
- **Subnet Groups**: Dedicated subnet group for data isolation

### Access Control
- **Network ACLs**: Additional network-level access control
- **Security Group Rules**: Port-based access control (6379)
- **Private Endpoints**: No direct internet access

## Monitoring & Alerting

### CloudWatch Metrics
- **CPUUtilization**: Percentage of CPU utilization
- **DatabaseMemoryUsagePercentage**: Memory usage percentage
- **NetworkBytesIn/Out**: Network traffic metrics
- **CacheHits/Misses**: Cache performance metrics

### Alarms Configured
1. **CPU Utilization Alarm**
   - Threshold: > 80%
   - Evaluation: 2 consecutive periods (10 minutes)
   - Statistic: Average

2. **Memory Utilization Alarm**
   - Threshold: > 80%
   - Evaluation: 2 consecutive periods (10 minutes)
   - Statistic: Average

### Additional Monitoring
```hcl
# Custom CloudWatch alarm example
resource "aws_cloudwatch_metric_alarm" "cache_hit_ratio" {
  alarm_name          = "redis-cache-hit-ratio-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.8"  # 80% hit ratio
  alarm_description   = "Cache hit ratio is below acceptable threshold"
  
  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
}
```

## Backup & Recovery

### Automatic Snapshots
- **Daily Snapshots**: Automatically created during snapshot window
- **Retention**: Configurable retention period
- **Cross-AZ**: Snapshots stored across multiple AZs

### Manual Snapshots
```bash
# Create manual snapshot
aws elasticache create-snapshot \
  --replication-group-id koneksi-staging-redis \
  --snapshot-name manual-snapshot-$(date +%Y%m%d%H%M%S)

# Restore from snapshot
aws elasticache create-replication-group \
  --replication-group-id koneksi-staging-redis-restored \
  --snapshot-name manual-snapshot-20231201120000
```

## Application Integration

### Connection Examples

#### Python (redis-py)
```python
import redis

# Connect to primary endpoint for writes
primary_client = redis.Redis(
    host='koneksi-staging-redis.xxxxx.cache.amazonaws.com',
    port=6379,
    decode_responses=True,
    ssl=True
)

# Connect to reader endpoint for reads
reader_client = redis.Redis(
    host='koneksi-staging-redis-ro.xxxxx.cache.amazonaws.com',
    port=6379,
    decode_responses=True,
    ssl=True
)

# Write operations
primary_client.set('user:123', 'john_doe')
primary_client.hset('session:abc', 'user_id', '123')

# Read operations
user = reader_client.get('user:123')
session = reader_client.hgetall('session:abc')
```

#### Node.js (ioredis)
```javascript
const Redis = require('ioredis');

// Primary client for writes
const primary = new Redis({
  host: 'koneksi-staging-redis.xxxxx.cache.amazonaws.com',
  port: 6379,
  tls: {}
});

// Reader client for reads
const reader = new Redis({
  host: 'koneksi-staging-redis-ro.xxxxx.cache.amazonaws.com',
  port: 6379,
  tls: {}
});

// Write operations
await primary.set('user:123', 'john_doe');
await primary.hset('session:abc', 'user_id', '123');

// Read operations
const user = await reader.get('user:123');
const session = await reader.hgetall('session:abc');
```

#### Go (go-redis)
```go
package main

import (
    "crypto/tls"
    "github.com/go-redis/redis/v8"
)

// Primary client for writes
primaryClient := redis.NewClient(&redis.Options{
    Addr:     "koneksi-staging-redis.xxxxx.cache.amazonaws.com:6379",
    TLSConfig: &tls.Config{},
})

// Reader client for reads
readerClient := redis.NewClient(&redis.Options{
    Addr:     "koneksi-staging-redis-ro.xxxxx.cache.amazonaws.com:6379",
    TLSConfig: &tls.Config{},
})

// Write operations
primaryClient.Set(ctx, "user:123", "john_doe", 0)
primaryClient.HSet(ctx, "session:abc", "user_id", "123")

// Read operations
user := readerClient.Get(ctx, "user:123")
session := readerClient.HGetAll(ctx, "session:abc")
```

## Cost Optimization

### Right-Sizing
- **Monitor Utilization**: Use CloudWatch metrics to right-size instances
- **Reserved Instances**: Purchase reserved capacity for predictable workloads
- **Spot Instances**: Not available for ElastiCache

### Data Management
- **TTL Policies**: Set appropriate expiration times for cached data
- **Memory Policies**: Use appropriate eviction policies
- **Data Compression**: Compress large values before storing

## Dependencies

- **VPC Module**: Provides network infrastructure and security groups
- **Security Groups**: For network access control
- **KMS**: For encryption key management
- **CloudWatch**: For monitoring and alerting

## Troubleshooting

### Connection Issues
1. Check security group rules (port 6379)
2. Verify subnet group configuration
3. Validate network ACLs
4. Check TLS/SSL configuration

### Performance Issues
1. Monitor CloudWatch metrics
2. Check cache hit ratio
3. Review memory utilization
4. Analyze slow log (if enabled)

### Failover Issues
1. Verify automatic failover is enabled
2. Check number of cache clusters (≥ 2 required)
3. Review Multi-AZ configuration
4. Monitor failover logs

## Best Practices

1. **Use Read Replicas**: Distribute read traffic across replicas
2. **Enable Automatic Failover**: Ensure high availability
3. **Monitor Cache Hit Ratio**: Aim for > 80% hit ratio
4. **Set Appropriate TTLs**: Prevent memory exhaustion
5. **Use Connection Pooling**: Optimize connection management
6. **Regular Monitoring**: Set up comprehensive CloudWatch alarms
7. **Backup Strategy**: Regular snapshots for data protection
8. **Security**: Always enable encryption in transit and at rest

## Integration with Other Modules

- **ECS**: Application containers connecting to Redis
- **ALB**: Session storage for load-balanced applications
- **VPC**: Network isolation and security
- **CloudWatch**: Monitoring and alerting
- **Parameter Store**: Configuration management

## Maintenance

- **Regular Updates**: Keep Redis version updated
- **Monitor Performance**: Regular performance analysis
- **Backup Verification**: Test backup and restore procedures
- **Security Reviews**: Regular security configuration reviews
- **Cost Optimization**: Monitor and optimize costs
- **Capacity Planning**: Plan for growth and scaling

## Support

For issues related to:
- **Connectivity**: Check security groups and network configuration
- **Performance**: Analyze CloudWatch metrics and optimize configuration
- **Failover**: Verify Multi-AZ setup and automatic failover settings
- **Security**: Review encryption and access control settings
- **Backup**: Verify snapshot configuration and test restore procedures