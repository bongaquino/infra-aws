# Virtual Private Cloud (VPC) Module

This module provisions a comprehensive, production-ready VPC infrastructure with multi-tier networking, security groups, VPC endpoints, and NAT gateways for the Koneksi infrastructure.

## Overview

The VPC module creates a robust network foundation supporting both new VPC creation and existing VPC management. It implements a three-tier architecture with public, private, and data private subnets across multiple availability zones, providing isolation, security, and high availability.

## Features

- **Multi-AZ Deployment**: Spans multiple availability zones for high availability
- **Three-Tier Architecture**: Public, private, and data private subnet layers
- **Internet Gateway**: Managed internet access for public subnets
- **NAT Gateways**: Secure internet access for private subnets
- **VPC Endpoints**: Private connectivity to AWS services (SSM, ECR)
- **Security Groups**: Pre-configured security groups for different tiers
- **Route Tables**: Optimized routing for each subnet tier
- **DNS Support**: Enabled DNS hostnames and resolution
- **Flexible Configuration**: Support for existing VPC import or new VPC creation
- **DHCP Options**: Customizable DHCP configuration

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                              VPC                                │
│                         10.0.0.0/16                            │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Public        │  │   Public        │  │   Public        │ │
│  │   Subnet AZ-1   │  │   Subnet AZ-2   │  │   Subnet AZ-3   │ │
│  │  10.0.1.0/24    │  │  10.0.2.0/24    │  │  10.0.3.0/24    │ │
│  │                 │  │                 │  │                 │ │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │ │
│  │  │    ALB    │  │  │  │NAT Gateway│  │  │  │    EIP    │  │ │
│  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                     │                     │        │
│           ▼                     ▼                     ▼        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Private       │  │   Private       │  │   Private       │ │
│  │   Subnet AZ-1   │  │   Subnet AZ-2   │  │   Subnet AZ-3   │ │
│  │  10.0.11.0/24   │  │  10.0.12.0/24   │  │  10.0.13.0/24   │ │
│  │                 │  │                 │  │                 │ │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │ │
│  │  │    ECS    │  │  │  │    EC2    │  │  │  │   Lambda  │  │ │
│  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                     │                     │        │
│           ▼                     ▼                     ▼        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Data Private    │  │ Data Private    │  │ Data Private    │ │
│  │  Subnet AZ-1    │  │  Subnet AZ-2    │  │  Subnet AZ-3    │ │
│  │  10.0.21.0/24   │  │  10.0.22.0/24   │  │  10.0.23.0/24   │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │   RDS       │ │  │ │ElastiCache  │ │  │ │  DynamoDB   │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Internet       │
                    │  Gateway        │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Internet      │
                    └─────────────────┘
```

## Directory Structure

```
vpc/
├── main.tf              # Main VPC configuration and resources
├── variables.tf         # Input variables and configuration
├── outputs.tf           # Output values
├── locals.tf            # Local values and computed variables
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── staging.tfvars       # Staging-specific values
├── prod.tfvars          # Production-specific values
├── run_terraform.sh     # Deployment script
├── envs/                # Environment-specific configurations
│   ├── staging/
│   ├── uat/
│   └── prod/
└── README.md           # This documentation
```

## Resources Created

### Core VPC Resources
- **aws_vpc**: Virtual Private Cloud with DNS support
- **aws_internet_gateway**: Internet access for public subnets
- **aws_subnet**: Public, private, and data private subnets
- **aws_nat_gateway**: NAT gateways for private subnet internet access
- **aws_eip**: Elastic IPs for NAT gateways
- **aws_route_table**: Route tables for each subnet tier
- **aws_route_table_association**: Subnet-to-route-table associations

### Security Resources
- **aws_security_group**: ALB, private, and VPC endpoint security groups
- **aws_vpc_dhcp_options**: Custom DHCP options (optional)

### VPC Endpoints
- **aws_vpc_endpoint.ssm**: Systems Manager endpoint
- **aws_vpc_endpoint.ssmmessages**: Systems Manager Messages endpoint
- **aws_vpc_endpoint.ecr_api**: ECR API endpoint
- **aws_vpc_endpoint.ecr_dkr**: ECR Docker endpoint

## Usage

### New VPC Creation

```hcl
module "vpc" {
  source = "./vpc"
  
  # Basic configuration
  environment = "staging"
  project     = "koneksi"
  name_prefix = "koneksi-staging"
  aws_region  = "ap-southeast-1"
  
  # VPC configuration
  vpc_cidr = "10.0.0.0/16"
  az_count = 2
  
  # Subnet configuration
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  
  public_subnets = {
    "public-1a" = {
      id         = ""  # Will be created
      cidr_block = "10.0.1.0/24"
      az         = "ap-southeast-1a"
    },
    "public-1b" = {
      id         = ""  # Will be created
      cidr_block = "10.0.2.0/24"
      az         = "ap-southeast-1b"
    }
  }
  
  private_subnets = {
    "private-1a" = {
      id         = ""  # Will be created
      cidr_block = "10.0.11.0/24"
      az         = "ap-southeast-1a"
    },
    "private-1b" = {
      id         = ""  # Will be created
      cidr_block = "10.0.12.0/24"
      az         = "ap-southeast-1b"
    }
  }
  
  database_subnets = {
    "data-1a" = {
      id         = ""  # Will be created
      cidr_block = "10.0.21.0/24"
      az         = "ap-southeast-1a"
    },
    "data-1b" = {
      id         = ""  # Will be created
      cidr_block = "10.0.22.0/24"
      az         = "ap-southeast-1b"
    }
  }
  
  # Feature flags
  create_nat_gateways    = true
  create_vpc_endpoints   = true
  create_security_groups = true
  
  # Tags
  tags = {
    Environment = "staging"
    Project     = "koneksi"
    Owner       = "devops-team"
  }
}
```

### Existing VPC Management

```hcl
module "vpc" {
  source = "./vpc"
  
  # Use existing VPC
  vpc_id   = "vpc-0123456789abcdef0"
  vpc_cidr = "10.0.0.0/16"  # Must match existing VPC
  
  # Reference existing subnets
  public_subnets = {
    "public-1a" = {
      id         = "subnet-0123456789abcdef0"
      cidr_block = "10.0.1.0/24"
      az         = "ap-southeast-1a"
    }
  }
  
  # Reference existing resources
  route_tables = {
    public = {
      id = "rtb-0123456789abcdef0"
    }
    private = {
      "private-1a" = {
        id = "rtb-0123456789abcdef1"
      }
    }
    data_private = {}
  }
  
  # Only create new resources as needed
  create_security_groups = true
  create_vpc_endpoints   = true
}
```

### Production Configuration

```hcl
module "vpc" {
  source = "./vpc"
  
  # ... basic configuration ...
  
  # Multi-AZ production setup
  az_count = 3
  availability_zones = [
    "ap-southeast-1a", 
    "ap-southeast-1b", 
    "ap-southeast-1c"
  ]
  
  # Larger address space
  vpc_cidr = "10.0.0.0/16"
  
  # Production subnets
  public_subnets = {
    "public-1a" = { cidr_block = "10.0.1.0/24", az = "ap-southeast-1a" },
    "public-1b" = { cidr_block = "10.0.2.0/24", az = "ap-southeast-1b" },
    "public-1c" = { cidr_block = "10.0.3.0/24", az = "ap-southeast-1c" }
  }
  
  private_subnets = {
    "private-1a" = { cidr_block = "10.0.11.0/24", az = "ap-southeast-1a" },
    "private-1b" = { cidr_block = "10.0.12.0/24", az = "ap-southeast-1b" },
    "private-1c" = { cidr_block = "10.0.13.0/24", az = "ap-southeast-1c" }
  }
  
  database_subnets = {
    "data-1a" = { cidr_block = "10.0.21.0/24", az = "ap-southeast-1a" },
    "data-1b" = { cidr_block = "10.0.22.0/24", az = "ap-southeast-1b" },
    "data-1c" = { cidr_block = "10.0.23.0/24", az = "ap-southeast-1c" }
  }
  
  # Production security
  create_vpc_endpoints = true
  
  # Additional tags
  tags = {
    Environment  = "production"
    Compliance   = "required"
    Backup       = "required"
    Monitoring   = "enhanced"
  }
}
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | string | - | Deployment environment (staging/uat/prod) |
| `project` | string | `koneksi` | Project name for naming and tagging |
| `name_prefix` | string | - | Prefix for resource names |
| `aws_region` | string | `ap-southeast-1` | AWS region for deployment |

### VPC Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_id` | string | `null` | Existing VPC ID (null creates new VPC) |
| `vpc_cidr` | string | `10.0.0.0/16` | CIDR block for VPC |
| `az_count` | number | `2` | Number of availability zones |
| `availability_zones` | list(string) | - | List of availability zones to use |

### Subnet Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `public_subnets` | map(object) | - | Public subnet configurations |
| `private_subnets` | map(object) | - | Private subnet configurations |
| `database_subnets` | map(object) | - | Database subnet configurations |
| `elasticache_subnets` | map(object) | - | ElastiCache subnet configurations |

### Feature Flags
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_igw` | bool | `true` | Create Internet Gateway |
| `create_nat_gateways` | bool | `true` | Create NAT Gateways |
| `create_route_tables` | bool | `true` | Create route tables |
| `create_security_groups` | bool | `true` | Create security groups |
| `create_vpc_endpoints` | bool | `true` | Create VPC endpoints |
| `create_dhcp_options` | bool | `true` | Create DHCP options |

### Existing Resources
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `internet_gateway_id` | string | `null` | Existing Internet Gateway ID |
| `nat_gateways` | map(object) | `{}` | Existing NAT Gateway configurations |
| `route_tables` | object | `{}` | Existing route table configurations |
| `security_groups` | object | `{}` | Existing security group configurations |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

### VPC Information
| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR block |

### Subnet Information
| Output | Description |
|--------|-------------|
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `data_private_subnet_ids` | List of data private subnet IDs |

### Networking Resources
| Output | Description |
|--------|-------------|
| `nat_gateway_ids` | Map of NAT Gateway IDs |
| `nat_gateway_public_ips` | Map of NAT Gateway Elastic IPs |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | List of private route table IDs |
| `data_private_route_table_ids` | List of data private route table IDs |

### VPC Endpoints
| Output | Description |
|--------|-------------|
| `vpc_endpoint_ssm_id` | SSM VPC endpoint ID |
| `vpc_endpoint_ssmmessages_id` | SSM Messages VPC endpoint ID |
| `vpc_endpoint_ecr_api_id` | ECR API VPC endpoint ID |
| `vpc_endpoint_ecr_dkr_id` | ECR Docker VPC endpoint ID |

### Security Groups
| Output | Description |
|--------|-------------|
| `vpc_endpoint_security_group_id` | VPC endpoint security group ID |
| `private_security_group_id` | Private security group ID |

## Subnet Design

### Public Subnets (10.0.1.0/24 - 10.0.3.0/24)
- **Purpose**: Internet-facing resources
- **Resources**: ALB, NAT Gateways, Bastion Hosts
- **Internet Access**: Direct via Internet Gateway
- **Security**: Public security group

### Private Subnets (10.0.11.0/24 - 10.0.13.0/24)
- **Purpose**: Application layer
- **Resources**: ECS tasks, EC2 instances, Lambda functions
- **Internet Access**: Via NAT Gateway
- **Security**: Private security group

### Data Private Subnets (10.0.21.0/24 - 10.0.23.0/24)
- **Purpose**: Database and cache layer
- **Resources**: RDS, ElastiCache, DynamoDB VPC endpoints
- **Internet Access**: None (VPC endpoints for AWS services)
- **Security**: Data private security group

## CIDR Block Recommendations

### Small Environment (Development/Testing)
```hcl
vpc_cidr = "10.0.0.0/16"

# Public subnets (256 IPs each)
public_subnets = {
  "public-1a" = { cidr_block = "10.0.1.0/24" }
  "public-1b" = { cidr_block = "10.0.2.0/24" }
}

# Private subnets (256 IPs each)
private_subnets = {
  "private-1a" = { cidr_block = "10.0.11.0/24" }
  "private-1b" = { cidr_block = "10.0.12.0/24" }
}

# Data private subnets (256 IPs each)
database_subnets = {
  "data-1a" = { cidr_block = "10.0.21.0/24" }
  "data-1b" = { cidr_block = "10.0.22.0/24" }
}
```

### Large Environment (Production)
```hcl
vpc_cidr = "10.0.0.0/16"

# Public subnets (1024 IPs each)
public_subnets = {
  "public-1a" = { cidr_block = "10.0.1.0/22" }
  "public-1b" = { cidr_block = "10.0.5.0/22" }
  "public-1c" = { cidr_block = "10.0.9.0/22" }
}

# Private subnets (1024 IPs each)
private_subnets = {
  "private-1a" = { cidr_block = "10.0.32.0/22" }
  "private-1b" = { cidr_block = "10.0.36.0/22" }
  "private-1c" = { cidr_block = "10.0.40.0/22" }
}

# Data private subnets (1024 IPs each)
database_subnets = {
  "data-1a" = { cidr_block = "10.0.64.0/22" }
  "data-1b" = { cidr_block = "10.0.68.0/22" }
  "data-1c" = { cidr_block = "10.0.72.0/22" }
}
```

## Security Groups

### ALB Security Group
- **Purpose**: Application Load Balancer access
- **Ingress**: HTTP (80), HTTPS (443), Custom (8081)
- **Egress**: All traffic

### Private Security Group
- **Purpose**: Private subnet resources
- **Ingress**: From ALB security group
- **Egress**: All traffic

### VPC Endpoint Security Group
- **Purpose**: VPC endpoint access
- **Ingress**: HTTPS (443) from private security group
- **Egress**: None specified

## VPC Endpoints

### Systems Manager (SSM)
- **Service**: `com.amazonaws.ap-southeast-1.ssm`
- **Type**: Interface
- **Purpose**: Parameter Store access from private subnets

### SSM Messages
- **Service**: `com.amazonaws.ap-southeast-1.ssmmessages`
- **Type**: Interface
- **Purpose**: Session Manager communication

### ECR API
- **Service**: `com.amazonaws.ap-southeast-1.ecr.api`
- **Type**: Interface
- **Purpose**: ECR registry API access

### ECR Docker
- **Service**: `com.amazonaws.ap-southeast-1.ecr.dkr`
- **Type**: Interface
- **Purpose**: Docker image pulls from ECR

## Route Tables

### Public Route Table
- **Default Route**: 0.0.0.0/0 → Internet Gateway
- **Local Route**: 10.0.0.0/16 → Local
- **Associated Subnets**: All public subnets

### Private Route Tables (per AZ)
- **Default Route**: 0.0.0.0/0 → NAT Gateway (in same AZ)
- **Local Route**: 10.0.0.0/16 → Local
- **Associated Subnets**: Private subnets in same AZ

### Data Private Route Tables (per AZ)
- **Local Route**: 10.0.0.0/16 → Local
- **VPC Endpoint Routes**: Via VPC endpoints
- **Associated Subnets**: Data private subnets in same AZ

## Cost Considerations

### NAT Gateways
- **Hourly Charge**: ~$45/month per NAT Gateway
- **Data Processing**: $0.045 per GB
- **Optimization**: Use single NAT Gateway for development

### VPC Endpoints
- **Interface Endpoints**: ~$7/month per endpoint
- **Data Processing**: $0.01 per GB
- **Benefit**: Reduces NAT Gateway data charges

### Elastic IPs
- **Associated**: Free when attached to running instance
- **Unassociated**: $0.005/hour (~$3.6/month)

## High Availability & Disaster Recovery

### Multi-AZ Design
- **Minimum 2 AZs**: For high availability
- **Production 3 AZs**: For enhanced resilience
- **AZ Failure**: Automatic failover via ALB and Auto Scaling

### NAT Gateway Redundancy
- **Per-AZ NAT Gateways**: Eliminates single point of failure
- **Automatic Failover**: Route tables automatically route to available NAT Gateway

### Cross-AZ Communication
- **Low Latency**: Optimized routing within region
- **No Additional Charges**: For cross-AZ traffic within VPC

## Best Practices

### Network Design
1. **Plan CIDR Blocks**: Avoid overlaps with on-premises networks
2. **Reserve Space**: Plan for future growth
3. **Consistent Naming**: Use environment-specific naming conventions
4. **Documentation**: Document IP ranges and purposes

### Security
1. **Least Privilege**: Minimal security group rules
2. **Layer Defense**: Multiple security layers
3. **Regular Audits**: Review security group rules
4. **VPC Flow Logs**: Enable for monitoring

### Cost Optimization
1. **Single NAT**: Use one NAT Gateway for development
2. **VPC Endpoints**: For high-volume AWS API calls
3. **Right-sizing**: Choose appropriate instance types
4. **Monitor Usage**: Track data transfer costs

### Operational
1. **Tagging**: Consistent resource tagging
2. **Monitoring**: CloudWatch metrics and alarms
3. **Automation**: Infrastructure as code
4. **Testing**: Regular disaster recovery testing

## Troubleshooting

### Connectivity Issues

#### No Internet Access from Private Subnets
1. Check NAT Gateway status and health
2. Verify route table associations
3. Confirm security group rules
4. Check NACL rules

#### VPC Endpoint Connection Issues
1. Verify endpoint is in correct subnets
2. Check security group rules (port 443)
3. Confirm DNS resolution is working
4. Verify endpoint policy (if custom)

#### Cross-Subnet Communication Problems
1. Check security group rules
2. Verify route table configurations
3. Confirm NACL rules
4. Check subnet CIDR overlaps

### Resource Limits
1. **VPC Limit**: 5 VPCs per region (default)
2. **Subnet Limit**: 200 subnets per VPC
3. **Route Table Limit**: 200 route tables per VPC
4. **Security Group Limit**: 2,500 per VPC

## Dependencies

- **AWS Provider**: Requires AWS provider configuration
- **Availability Zones**: Requires available AZs in region
- **Route53**: For DNS resolution (optional)
- **CloudWatch**: For monitoring and logging

## Integration with Other Modules

- **ECS**: Uses private subnets for task placement
- **ALB**: Uses public subnets for load balancer placement
- **RDS**: Uses data private subnets for database instances
- **ElastiCache**: Uses data private subnets for cache clusters
- **Parameter Store**: Accessed via VPC endpoints

## Maintenance

- **Regular Reviews**: Monthly review of security groups and NACLs
- **Cost Monitoring**: Monitor NAT Gateway and VPC endpoint costs
- **Capacity Planning**: Monitor IP address utilization
- **Security Updates**: Keep security groups and policies updated
- **Documentation**: Maintain network documentation
- **Backup**: Export VPC configuration for disaster recovery

## Support

For issues related to:
- **Connectivity**: Check routing tables and security groups
- **Performance**: Monitor CloudWatch metrics and VPC Flow Logs  
- **Security**: Review security group rules and NACLs
- **Cost**: Analyze NAT Gateway and VPC endpoint usage
- **Scaling**: Plan CIDR blocks and subnet capacity