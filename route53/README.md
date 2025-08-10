# AWS Route 53 Module

This module provisions comprehensive DNS management infrastructure using Amazon Route 53 with advanced routing policies, health monitoring, and traffic management capabilities. It provides enterprise-grade DNS services with high availability, global load balancing, and automated failover mechanisms.

## Overview

The Route 53 module creates a robust DNS infrastructure that supports complex routing scenarios, geographic routing, weighted routing, and health-based failover. It integrates with other AWS services to provide intelligent traffic management and comprehensive monitoring for optimal application performance and availability.

## Features

- **Hosted Zone Management**: Comprehensive DNS zone management with lifecycle protection
- **Multiple Record Types**: Support for A, AAAA, CNAME, MX, TXT, SRV, and NS records
- **Advanced Routing Policies**: Weighted, latency-based, geolocation, and failover routing
- **Health Checks**: Automated health monitoring with failover capabilities
- **Email Authentication**: SPF, DKIM, and DMARC record configuration
- **Subdomain Management**: Flexible subdomain and wildcard record support
- **Traffic Management**: Intelligent traffic distribution and load balancing
- **SSL/TLS Integration**: Seamless integration with ACM for certificate validation
- **AWS Service Integration**: Native integration with ALB, CloudFront, and Amplify
- **High Availability**: Multi-region failover and disaster recovery support

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Internet & DNS Queries                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   End Users     │  │   Search Bots   │  │      Email Servers          │ │
│  │  (Global)       │  │   (Crawlers)    │  │      (SMTP/IMAP)            │ │
│  └─────────┬───────┘  └─────────┬───────┘  └─────────────┬───────────────┘ │
└───────────┼────────────────────┼────────────────────────┼─────────────────┘
            │                    │                        │                  
            └────────────────────┼────────────────────────┘                  
                                 │                                           
┌─────────────────────────────────▼─────────────────────────────────────────┐ 
│                         Route 53 DNS Service                              │ 
│                                                                           │ 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐│ 
│  │  Hosted Zone    │  │  Health Checks  │  │       Routing Policies      ││ 
<<<<<<< HEAD
│  │ bongaquino.com   │  │   & Monitoring  │  │                             ││ 
=======
│  │ bongaquino.co.kr   │  │   & Monitoring  │  │                             ││ 
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
│  │                 │  │                 │  │  • Weighted Routing         ││ 
│  │ • A Records     │  │ • Endpoint      │  │  • Latency-based            ││ 
│  │ • CNAME Records │  │   Health        │  │  • Geolocation              ││ 
│  │ • MX Records    │  │ • Failover      │  │  • Failover                 ││ 
│  │ • TXT Records   │  │   Detection     │  │  • Multivalue Answer        ││ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘│ 
└─────────────────────────────────┬─────────────────────────────────────────┘ 
                                  │                                           
┌─────────────────────────────────▼─────────────────────────────────────────┐ 
│                           AWS Services & Endpoints                        │ 
│                                                                           │ 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐│ 
│  │   Application   │  │   CloudFront    │  │        Amplify              ││ 
│  │ Load Balancers  │  │  Distributions  │  │     Applications            ││ 
│  │                 │  │                 │  │                             ││ 
│  │ • ALB (staging) │  │ • Global CDN    │  │  • Frontend Apps            ││ 
│  │ • NLB (prod)    │  │ • Edge Locations│  │  • Auto-scaling             ││ 
│  │ • Health Checks │  │ • SSL/TLS       │  │  • CI/CD Integration        ││ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘│ 
│                                                                           │ 
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐│ 
│  │   EC2/ECS       │  │   External      │  │       Email Services        ││ 
│  │   Instances     │  │   Services      │  │                             ││ 
│  │                 │  │                 │  │  • Microsoft 365            ││ 
│  │ • Web Servers   │  │ • Third-party   │  │  • SMTP Relays              ││ 
│  │ • API Servers   │  │   APIs          │  │  • Email Authentication     ││ 
│  │ • Database      │  │ • CDN Services  │  │  • SPF/DKIM/DMARC          ││ 
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘│ 
└───────────────────────────────────────────────────────────────────────────┘ 
```

## Directory Structure

```
route53/
├── README.md                    # This documentation
├── main.tf                      # Core Route 53 resources
├── variables.tf                 # Input variables
├── outputs.tf                   # Module outputs
├── backend.tf                   # Backend configuration
├── terraform.tfvars             # Variable values
└── health-checks.tf             # Health check configurations (optional)
```

## Resources Created

### Core DNS Resources
- **aws_route53_zone**: Primary hosted zone with lifecycle protection
- **aws_route53_record**: DNS records for various record types
- **aws_route53_health_check**: Health monitoring for endpoints
- **aws_route53_query_log**: DNS query logging configuration

### Advanced Features
- **aws_route53_resolver_endpoint**: Private DNS resolution
- **aws_route53_resolver_rule**: DNS forwarding rules
- **aws_cloudwatch_metric_alarm**: DNS monitoring and alerting

## Current Domain Configuration

### Primary Domain Records
<<<<<<< HEAD
- **Root Domain**: `bongaquino.com`
- **WWW Subdomain**: `www.bongaquino.com` → Personal portfolio hosting
=======
- **Root Domain**: `bongaquino.co.kr`
- **WWW Subdomain**: `www.bongaquino.co.kr` → Wix hosting
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
- **Staging Environment**: `staging.bongaquino.co.kr` → AWS EC2
- **Application Staging**: `app-staging.bongaquino.co.kr` → AWS Amplify
- **UAT Environment**: `app-uat.bongaquino.co.kr` → AWS Amplify

### Service Endpoints
- **API Gateway**: `gateway.bongaquino.co.kr` → External server
- **IPFS Services**: `ipfs.bongaquino.co.kr` → IPFS nodes
- **Email Services**: MX records for Microsoft 365

### Email Configuration
- **MX Record**: `bongaquino-co-kr.mail.protection.outlook.com` (Microsoft 365)
- **Autodiscover**: `autodiscover.bongaquino.co.kr` → Outlook configuration
- **DKIM Authentication**: Configured for email security
- **SPF/DMARC**: Email authentication and anti-spoofing

## Usage

### Basic Domain Setup

```hcl
module "route53" {
  source = "./route53"

  # Basic domain configuration
  domain_name = "bongaquino.co.kr"
  aws_region  = "ap-southeast-1"
  
  # A records for primary services
  a_records = {
    "staging" = {
      name    = "staging.bongaquino.co.kr"
      records = ["52.77.36.120"]
      ttl     = 300
    }
    "gateway" = {
      name    = "gateway.bongaquino.co.kr"
      records = ["27.255.70.17"]
      ttl     = 300
    }
  }
  
  # CNAME records for subdomains
  cname_records = {
    "www" = {
      name    = "www.bongaquino.co.kr"
      records = ["balancer.wixdns.net."]
      ttl     = 300
    }
    "autodiscover" = {
      name    = "autodiscover.bongaquino.co.kr"
      records = ["autodiscover.outlook.com."]
      ttl     = 300
    }
  }
  
  tags = {
    Environment = "production"
<<<<<<< HEAD
    Project     = "bongaquino"
=======
    Project     = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  }
}
```

### Advanced Configuration with Health Checks

```hcl
module "route53_advanced" {
  source = "./route53"

  domain_name = "bongaquino.co.kr"
  
  # Alias records for AWS services
  alias_records = {
    "app-staging" = {
      name                   = "app-staging.bongaquino.co.kr"
      alias_name             = "d1numm9pbccz2w.cloudfront.net."
      alias_zone_id          = "Z2FDTNDATAQYW2"
      evaluate_target_health = false
    }
    "uat" = {
      name                   = "uat.bongaquino.co.kr"
      alias_name             = "dualstack.bongaquino-uat-alb-630040688.ap-southeast-1.elb.amazonaws.com."
      alias_zone_id          = "Z1LMS91P8CMLE5"
      evaluate_target_health = true
    }
  }
  
  # Health checks for monitoring
  health_checks = {
    "staging_endpoint" = {
      fqdn              = "staging.bongaquino.co.kr"
      port              = 443
      type              = "HTTPS"
      resource_path     = "/health"
      failure_threshold = 3
      request_interval  = 30
    }
    "api_gateway" = {
      fqdn              = "gateway.bongaquino.co.kr"
      port              = 80
      type              = "HTTP"
      resource_path     = "/status"
      failure_threshold = 2
      request_interval  = 10
    }
  }
  
  # Email configuration
  mx_records = {
    "main" = {
      name    = "bongaquino.co.kr"
      records = ["0 bongaquino-co-kr.mail.protection.outlook.com."]
      ttl     = 300
    }
  }
  
  # TXT records for email authentication
  txt_records = {
    "spf_dmarc" = {
      name    = "bongaquino.co.kr"
      records = [
        "MS=ms62474739",
        "_globalsign-domain-verification=ZP-vTECIFv7iE3MUd-yPRvNCiL8OWfyFTB-YinM08S"
      ]
      ttl = 300
    }
    "dkim_selector" = {
      name    = "20250604040914pm._domainkey.bongaquino.co.kr"
      records = ["k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDCsDAsE41iUNu31DwH9xTX6kcFuKvaUllZ3mp5A1dEiSnJs23HoT0TLzFY9bs/P9iMnY6jtRzhSTOFFBAX+PydIOWIm0AS7Bf3uA74NWUs8ZoXiHhLYgEKMxtxmJJONa5gfMHLzWrmR+tpyy/qNElwnCV1SRnG+cp1x+3+4NiE0QIDAQAB"]
      ttl     = 300
    }
  }
}
```

### Weighted Routing for Blue-Green Deployments

```hcl
module "route53_weighted" {
  source = "./route53"

  domain_name = "bongaquino.co.kr"
  
  # Weighted routing for gradual traffic shifting
  weighted_records = {
    "api_blue" = {
      name            = "api.bongaquino.co.kr"
      type            = "A"
      records         = ["10.0.1.100"]
      ttl             = 60
      weight          = 80
      set_identifier  = "blue"
      health_check_id = aws_route53_health_check.api_blue.id
    }
    "api_green" = {
      name            = "api.bongaquino.co.kr"
      type            = "A"
      records         = ["10.0.2.100"]
      ttl             = 60
      weight          = 20
      set_identifier  = "green"
      health_check_id = aws_route53_health_check.api_green.id
    }
  }
}
```

### Geolocation Routing

```hcl
module "route53_geo" {
  source = "./route53"

  domain_name = "bongaquino.co.kr"
  
  # Geographic routing for global applications
  geolocation_records = {
    "api_asia" = {
      name                = "api.bongaquino.co.kr"
      type                = "A"
      records             = ["52.77.36.120"]
      ttl                 = 300
      set_identifier      = "asia-pacific"
      geolocation_continent = "AS"
    }
    "api_default" = {
      name                = "api.bongaquino.co.kr"
      type                = "A"
      records             = ["54.156.159.169"]
      ttl                 = 300
      set_identifier      = "default"
      geolocation_default = true
    }
  }
}
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `domain_name` | string | `"bongaquino.co.kr"` | Primary domain name for the hosted zone |
| `aws_region` | string | `"ap-southeast-1"` | AWS region for resources |
| `enable_lifecycle_protection` | bool | `true` | Enable lifecycle protection for critical records |

### Record Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `a_records` | map(object) | `{}` | Map of A record configurations |
| `aaaa_records` | map(object) | `{}` | Map of AAAA record configurations |
| `cname_records` | map(object) | `{}` | Map of CNAME record configurations |
| `mx_records` | map(object) | `{}` | Map of MX record configurations |
| `txt_records` | map(object) | `{}` | Map of TXT record configurations |
| `srv_records` | map(object) | `{}` | Map of SRV record configurations |

### Advanced Routing
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `alias_records` | map(object) | `{}` | Map of alias record configurations |
| `weighted_records` | map(object) | `{}` | Map of weighted routing configurations |
| `latency_records` | map(object) | `{}` | Map of latency-based routing configurations |
| `geolocation_records` | map(object) | `{}` | Map of geolocation routing configurations |
| `failover_records` | map(object) | `{}` | Map of failover routing configurations |

### Health Monitoring
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `health_checks` | map(object) | `{}` | Map of health check configurations |
| `enable_query_logging` | bool | `false` | Enable DNS query logging |
| `query_log_destination` | string | `""` | CloudWatch log group for query logs |

### Tagging
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `zone_id` | The ID of the Route 53 hosted zone |
| `zone_arn` | The ARN of the Route 53 hosted zone |
| `name_servers` | List of name servers for the hosted zone |
| `domain_name` | The domain name of the hosted zone |
| `record_names` | List of all DNS record names created |
| `health_check_ids` | Map of health check names to their IDs |
| `health_check_arns` | Map of health check names to their ARNs |

## DNS Record Types

### A Records (IPv4 Addresses)
```hcl
a_records = {
  "staging" = {
    name    = "staging.bongaquino.co.kr"
    records = ["52.77.36.120"]
    ttl     = 300
  }
}
```

### AAAA Records (IPv6 Addresses)
```hcl
aaaa_records = {
  "ipv6_server" = {
    name    = "ipv6.bongaquino.co.kr"
    records = ["2001:db8::1"]
    ttl     = 300
  }
}
```

### CNAME Records (Canonical Names)
```hcl
cname_records = {
  "www" = {
    name    = "www.bongaquino.co.kr"
    records = ["balancer.wixdns.net."]
    ttl     = 300
  }
}
```

### MX Records (Mail Exchange)
```hcl
mx_records = {
  "email" = {
    name    = "bongaquino.co.kr"
    records = ["0 bongaquino-co-kr.mail.protection.outlook.com."]
    ttl     = 300
  }
}
```

### TXT Records (Text Records)
```hcl
txt_records = {
  "verification" = {
    name    = "bongaquino.co.kr"
    records = [
      "MS=ms62474739",
      "v=spf1 include:spf.protection.outlook.com -all"
    ]
    ttl = 300
  }
}
```

### Alias Records (AWS Services)
```hcl
alias_records = {
  "cloudfront" = {
    name                   = "cdn.bongaquino.co.kr"
    alias_name             = "d1234567890.cloudfront.net."
    alias_zone_id          = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
```

## Health Checks & Monitoring

### Basic Health Check Configuration
```hcl
resource "aws_route53_health_check" "web_server" {
  fqdn                          = "staging.bongaquino.co.kr"
  port                          = 443
  type                          = "HTTPS"
  resource_path                 = "/health"
  failure_threshold             = 3
  request_interval              = 30
  measure_latency               = true
  enable_sni                    = true
  
  tags = {
    Name = "Web Server Health Check"
  }
}
```

### Advanced Health Check with Regions
```hcl
resource "aws_route53_health_check" "global_endpoint" {
  fqdn                          = "api.bongaquino.co.kr"
  port                          = 443
  type                          = "HTTPS_STR_MATCH"
  resource_path                 = "/api/health"
  failure_threshold             = 2
  request_interval              = 10
  search_string                 = "OK"
  cloudwatch_alarm_region       = "us-east-1"
  measure_latency               = true
  
  regions = ["us-east-1", "us-west-2", "eu-west-1"]
  
  tags = {
    Name        = "Global API Health Check"
    Environment = "production"
  }
}
```

### CloudWatch Integration
```hcl
resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
  alarm_name          = "route53-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors route53 health check"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.web_server.id
  }
}
```

## Advanced Routing Policies

### Failover Routing
```hcl
# Primary record
resource "aws_route53_record" "primary" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = "api.bongaquino.co.kr"
  type            = "A"
  ttl             = 60
  records         = ["10.0.1.100"]
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
  
  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Secondary record
resource "aws_route53_record" "secondary" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = "api.bongaquino.co.kr"
  type            = "A"
  ttl             = 60
  records         = ["10.0.2.100"]
  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.secondary.id
  
  failover_routing_policy {
    type = "SECONDARY"
  }
}
```

### Latency-Based Routing
```hcl
# US East region
resource "aws_route53_record" "us_east" {
  zone_id        = aws_route53_zone.main.zone_id
  name           = "api.bongaquino.co.kr"
  type           = "A"
  ttl            = 300
  records        = ["54.156.159.169"]
  set_identifier = "us-east-1"
  
  latency_routing_policy {
    region = "us-east-1"
  }
}

# Asia Pacific region
resource "aws_route53_record" "ap_southeast" {
  zone_id        = aws_route53_zone.main.zone_id
  name           = "api.bongaquino.co.kr"
  type           = "A"
  ttl            = 300
  records        = ["52.77.36.120"]
  set_identifier = "ap-southeast-1"
  
  latency_routing_policy {
    region = "ap-southeast-1"
  }
}
```

## Security & Compliance

### DNS Security Extensions (DNSSEC)
```hcl
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.main.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "bongaquino_dnssec_key"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  hosted_zone_id = aws_route53_zone.main.id
  depends_on     = [aws_route53_key_signing_key.main]
}
```

### Query Logging
```hcl
resource "aws_cloudwatch_log_group" "route53_query_log" {
  name              = "/aws/route53/bongaquino.co.kr"
  retention_in_days = 30
}

resource "aws_route53_query_log" "main" {
  depends_on   = [aws_cloudwatch_log_group.route53_query_log]
  destination_arn = aws_cloudwatch_log_group.route53_query_log.arn
  zone_id      = aws_route53_zone.main.zone_id
}
```

### Access Control
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::account:user/dns-admin"
      },
      "Action": [
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/Z123456789"
    }
  ]
}
```

## Best Practices

### DNS Configuration
1. **Use Appropriate TTL Values**: Balance between performance and flexibility
2. **Implement Health Checks**: Monitor endpoint availability for failover
3. **Plan for Disaster Recovery**: Configure multi-region failover
4. **Use Alias Records**: Leverage AWS service integration when possible
5. **Monitor DNS Performance**: Track query response times and error rates

### Security
1. **Enable DNSSEC**: Protect against DNS spoofing attacks
2. **Restrict Zone Access**: Use IAM policies for zone management
3. **Monitor DNS Queries**: Enable query logging for security analysis
4. **Regular Audits**: Review DNS configuration regularly
5. **Backup Configurations**: Maintain DNS configuration backups

### Performance
1. **Optimize TTL Values**: Use longer TTLs for stable records
2. **Use Geolocation Routing**: Route users to nearest endpoints
3. **Implement Caching**: Leverage DNS caching strategies
4. **Monitor Latency**: Track DNS resolution performance
5. **Load Distribution**: Use weighted routing for load balancing

### Operational
1. **Documentation**: Maintain comprehensive DNS documentation
2. **Change Management**: Implement controlled DNS change processes
3. **Testing**: Test DNS changes in staging environments
4. **Monitoring**: Set up comprehensive DNS monitoring
5. **Automation**: Use Infrastructure as Code for DNS management

## Troubleshooting

### Common Issues

#### DNS Resolution Problems
**Symptoms**: Domain not resolving or incorrect IP addresses
**Solutions**:
1. Check DNS propagation with `dig` or `nslookup`
2. Verify record configuration in Route 53
3. Check TTL values and wait for cache expiration
4. Validate name server delegation

#### Health Check Failures
**Symptoms**: Failover not working or false positives
**Solutions**:
1. Verify health check configuration
2. Check endpoint accessibility from Route 53 regions
3. Review health check logs in CloudWatch
4. Adjust failure thresholds and intervals

#### Email Delivery Issues
**Symptoms**: Emails not being delivered or marked as spam
**Solutions**:
1. Verify MX record configuration
2. Check SPF, DKIM, and DMARC records
3. Validate email authentication setup
4. Monitor email reputation scores

### Debugging Commands

```bash
# Check DNS resolution
dig bongaquino.co.kr
nslookup staging.bongaquino.co.kr

# Trace DNS resolution path
dig +trace bongaquino.co.kr

# Check specific record types
dig MX bongaquino.co.kr
dig TXT bongaquino.co.kr

# Verify name server delegation
dig NS bongaquino.co.kr

# Test health check status
aws route53 get-health-check --health-check-id HEALTH_CHECK_ID

# Monitor DNS queries
aws logs filter-log-events \
  --log-group-name /aws/route53/bongaquino.co.kr \
  --start-time 1640995200 \
  --end-time 1640998800

# Check DNS response times
dig @8.8.8.8 bongaquino.co.kr +stats
```

## Dependencies

- **AWS Certificate Manager**: SSL/TLS certificate validation
- **CloudWatch**: Monitoring and logging
- **SNS**: Health check notifications
- **KMS**: DNSSEC key management
- **IAM**: Access control and permissions

## Integration with Other Modules

- **ALB**: Application Load Balancer DNS integration
- **CloudFront**: CDN distribution endpoints
- **Amplify**: Application hosting and DNS
- **ACM**: Certificate validation records
- **VPC**: Private DNS resolution

## Maintenance

- **Health Check Monitoring**: Regular health check status review
- **DNS Performance**: Monthly DNS performance analysis
- **Record Updates**: Coordinate DNS changes with deployments
- **Security Audits**: Quarterly DNS security configuration review
- **Documentation**: Keep DNS documentation synchronized with changes

## Support

For issues related to:
- **DNS Resolution**: Check propagation and record configuration
- **Health Checks**: Verify endpoint accessibility and monitoring setup
- **Email Configuration**: Review MX, SPF, DKIM, and DMARC records
- **Performance**: Analyze DNS query patterns and optimization opportunities
- **Security**: Review access controls and enable security features

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | The domain name for the Route 53 hosted zone | `string` | `"bongaquino.co.kr"` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| ttl | The TTL (Time To Live) for all DNS records in seconds | `number` | `300` | no |
| root_domain_records | List of IP addresses for the root domain A record | `list(string)` | `[]` | no |
| www_domain_records | List of IP addresses for the www subdomain A record | `list(string)` | `[]` | no |
| mx_records | List of MX records for email routing | `list(string)` | `[]` | no |
| spf_records | List of SPF records for email authentication | `list(string)` | `[]` | no |
| dkim_selector | DKIM selector for the domain | `string` | `"default"` | no |
| dkim_records | List of DKIM records for email authentication | `list(string)` | `[]` | no |
| cname_records | Map of CNAME records where key is the subdomain and value is the target | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | The ID of the Route 53 hosted zone |
| name_servers | The name servers for the hosted zone |
| domain_name | The domain name of the hosted zone |

## Notes

- After applying this module, you'll need to update your domain registrar's name servers with the values from the `name_servers` output.
- Make sure to replace the example IP addresses and DNS records with your actual values.
- The TTL for all records is configurable through the `ttl` variable, defaulting to 300 seconds (5 minutes).
- Records are only created if their corresponding variable has values (empty lists/maps will not create records).
- For CNAME records, the key should be the subdomain name (e.g., "api" for api.bongaquino.co.kr) and the value should be the target domain. 