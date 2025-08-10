# AWS Certificate Manager (ACM) Module

This module provisions SSL/TLS certificates using AWS Certificate Manager for the bongaquino infrastructure.

## Overview

The ACM module creates SSL/TLS certificates with automatic DNS validation and lifecycle management. It supports both primary domains and subject alternative names (SANs) for multi-domain certificates.

## Features

- **SSL/TLS Certificate Management**: Automated certificate provisioning
- **DNS Validation**: Automatic validation using Route53 DNS records
- **Multi-Region Support**: Supports both regional and CloudFront (us-east-1) certificates
- **Subject Alternative Names**: Support for multiple domains on a single certificate
- **Lifecycle Management**: Automatic renewal and lifecycle protection
- **Terraform Integration**: Full infrastructure-as-code management

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Route53 Zone  │    │  ACM Certificate │    │   CloudFront    │
│  bongaquino.co.kr  │───▶│     (SSL/TLS)    │───▶│  Distribution   │
│                 │    │                 │    │   (us-east-1)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  DNS Validation │
                       │     Records     │
                       └─────────────────┘
```

## Directory Structure

```
acm/
├── main.tf              # Main ACM configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
└── README.md           # This documentation
```

## Resources Created

- **aws_acm_certificate**: SSL/TLS certificate with DNS validation
- **DNS Validation Records**: Automatic Route53 record creation for validation

## Usage

### Basic Configuration

```hcl
module "acm" {
  source = "./acm"
  
  domain_name = "bongaquino.co.kr"
  subject_alternative_names = [
    "*.bongaquino.co.kr",
    "api.bongaquino.co.kr",
    "app.bongaquino.co.kr"
  ]
}
```

### Environment-Specific Deployment

1. **Navigate to ACM directory**:
```bash
cd bongaquino-aws/acm
```

2. **Initialize Terraform**:
```bash
terraform init
```

3. **Plan the deployment**:
```bash
AWS_PROFILE=bongaquino terraform plan
```

4. **Apply the configuration**:
```bash
AWS_PROFILE=bongaquino terraform apply
```

## Input Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `ap-southeast-1` | AWS region to deploy resources |
| `domain_name` | string | - | The primary domain name for the ACM certificate |
| `subject_alternative_names` | list(string) | `[]` | List of subject alternative names for the certificate |
| `validation_method` | string | `DNS` | Validation method (DNS or EMAIL) |

## Outputs

| Output | Description |
|--------|-------------|
| `certificate_arn` | The ARN of the ACM certificate |
| `certificate_domain_name` | The domain name of the ACM certificate |
| `certificate_status` | The status of the ACM certificate |

## Certificate Validation

The module uses DNS validation which requires:

1. **Route53 Hosted Zone**: The domain must be managed by Route53
2. **DNS Records**: Validation records are automatically created
3. **Domain Ownership**: You must own the domain being validated

## Multi-Region Support

The module supports certificates for both:

- **Regional Services**: ALB, API Gateway (ap-southeast-1)
- **CloudFront**: Global distribution (us-east-1 provider)

```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
```

## Security Features

- **Lifecycle Protection**: `prevent_destroy = true` prevents accidental deletion
- **Automatic Renewal**: AWS automatically renews certificates before expiration
- **DNS Validation**: More secure than email validation
- **Encryption in Transit**: Ensures all traffic is encrypted

## Dependencies

- **Route53**: Requires existing hosted zone for DNS validation
- **IAM Permissions**: Requires ACM and Route53 permissions

## Example Configurations

### Single Domain Certificate

```hcl
domain_name = "api.bongaquino.co.kr"
subject_alternative_names = []
```

### Wildcard Certificate

```hcl
domain_name = "bongaquino.co.kr"
subject_alternative_names = ["*.bongaquino.co.kr"]
```

### Multi-Domain Certificate

```hcl
domain_name = "bongaquino.co.kr"
subject_alternative_names = [
  "*.bongaquino.co.kr",
  "app-staging.bongaquino.co.kr",
  "app-uat.bongaquino.co.kr",
  "api-staging.bongaquino.co.kr",
  "api-uat.bongaquino.co.kr"
]
```

## Monitoring

- **Certificate Status**: Monitor certificate validation and renewal status
- **CloudWatch Metrics**: ACM provides metrics for certificate events
- **DNS Validation**: Monitor Route53 for validation record creation

## Troubleshooting

### Certificate Validation Failed

1. Check Route53 hosted zone exists
2. Verify DNS validation records are created
3. Ensure domain ownership

### Certificate Not Renewing

1. Check DNS validation records are still present
2. Verify Route53 hosted zone is active
3. Review CloudWatch logs for ACM events

## Cost Considerations

- **ACM Certificates**: Free for AWS resources
- **Route53 Queries**: Minimal cost for DNS validation
- **No Renewal Costs**: Automatic renewal is included

## Best Practices

1. **Use DNS Validation**: More reliable than email validation
2. **Wildcard Certificates**: Use for multiple subdomains
3. **Lifecycle Protection**: Keep `prevent_destroy = true`
4. **Regular Monitoring**: Monitor certificate status and expiration
5. **Proper Tagging**: Use consistent tags for resource management

## Integration with Other Modules

- **ALB**: Uses certificate for HTTPS listeners
- **CloudFront**: Uses certificate for custom domains
- **API Gateway**: Uses certificate for custom domain names
- **Amplify**: Uses certificate for custom domains

## Maintenance

- **Review Certificate Usage**: Regularly audit which services use certificates
- **Monitor Expiration**: Set up alerts for certificate expiration
- **Update SANs**: Add new domains as needed
- **Clean Up Unused**: Remove unused certificates to reduce complexity

## Support

For issues related to:
- **Certificate Validation**: Check Route53 configuration
- **Certificate Usage**: Verify service configuration
- **DNS Issues**: Contact DNS administrator
- **AWS Issues**: Create AWS support ticket