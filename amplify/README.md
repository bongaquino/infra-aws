# AWS Amplify Module

This module provisions and manages AWS Amplify applications for hosting React/Vite applications in the bongaquino infrastructure, with full CI/CD pipeline integration and multi-environment support.

## Overview

The Amplify module creates a production-ready web hosting environment with automatic builds, deployments, and optimized caching. It supports multiple environments with branch-based deployments and optional custom domain configuration.

## Features

- **Automatic CI/CD**: Git-triggered builds and deployments
- **Multi-Environment Support**: Separate configurations for staging, UAT, and production
- **Custom Domain Support**: SSL/TLS certificates and domain association
- **Optimized Build Process**: PNPM-based builds with caching
- **SPA Routing**: Single-page application routing support
- **Environment Variables**: Dynamic configuration per environment
- **Performance Optimization**: Built-in CDN and caching
- **Security Headers**: Configurable security policies
- **Branch Management**: Multiple branch deployments
- **Lifecycle Protection**: Prevent accidental resource deletion

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   AWS Amplify   │    │   CloudFront    │
│   Repository    │───▶│   Build System  │───▶│   Distribution  │
│                 │    │                 │    │   (Global CDN)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       ▼
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │   S3 Bucket     │    │   Route53 DNS   │
         │              │  (Static Files) │    │ (Custom Domain) │
         │              └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Webhook       │    │   Build Logs    │    │   SSL/TLS       │
│   Triggers      │    │  (CloudWatch)   │    │  Certificate    │
│                 │    │                 │    │   (ACM)         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Directory Structure

```
amplify/
├── main.tf              # Main Amplify configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── terraform.tfvars     # Default variable values
├── README.md           # This documentation
├── modules/             # Sub-modules
│   └── app/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── envs/               # Environment-specific configurations
    ├── staging/
    │   ├── backend.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    ├── uat/
    │   ├── backend.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    └── prod/
        ├── backend.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

## Resources Created

### Core Amplify Resources
- **aws_amplify_app**: Main application with build configuration
- **aws_amplify_branch**: Environment-specific branch deployment
- **aws_amplify_domain_association**: Custom domain configuration (optional)
- **aws_amplify_webhook**: Automated deployment triggers (optional)

## Build Configuration

### Build Specification
The module uses an optimized build process for React/Vite applications:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm install -g pnpm
        - pnpm install
    build:
      commands:
        - pnpm run build
  artifacts:
    baseDirectory: dist
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
      - .pnpm-store/**/*
```

### Build Features
- **PNPM Package Manager**: Faster installs and better disk efficiency
- **Dependency Caching**: Caches `node_modules` and `.pnpm-store` for faster builds
- **Production Optimization**: Uses `pnpm run build` for production builds
- **Vite Framework**: Optimized for Vite-based React applications

### Environment Variables
Each environment can be configured with:
- **`VITE_ENVIRONMENT`**: Environment identifier for build-time configuration
- **Custom Variables**: Additional environment-specific variables as needed

### Current Deployments

#### Staging Environment
- **App Name**: `bongaquino-web-staging`
- **Branch**: `staging`
- **Domain**: `app-staging.example.com`
- **Environment**: `staging`
- **API URL**: `https://api-staging.example.com`

#### UAT Environment  
- **App Name**: `bongaquino-web-uat`
- **Branch**: `main`
- **Domain**: `app-uat.example.com`
- **Environment**: `production`
- **API URL**: `https://api-uat.example.com`

## Usage

### Basic Configuration

```hcl
module "amplify" {
  source = "./amplify"
  
  # Basic settings
  app_name         = "bongaquino-web-staging"
<<<<<<< HEAD
  repository       = "https://github.com/bongaquino/bongaquino-web"
=======
  repository       = "https://github.com/bongaquino-tech/bongaquino-web"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  github_token     = var.github_token
  
  # Branch configuration
  branch_name      = "staging"
  branch_stage     = "PRODUCTION"
  
  # Environment variables
  vite_environment = "staging"
  
  # Custom domain (optional)
  domain_name      = "app-staging.example.com"
  api_url         = "https://api-staging.example.com"
  
  # Tagging
  environment     = "staging"
<<<<<<< HEAD
  project         = "bongaquino"
=======
  project         = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  name_prefix     = "bongaquino-staging"
}
```

### Environment-Specific Deployment

1. **Navigate to environment directory**:
```bash
cd bongaquino-aws/amplify/envs/staging
```

2. **Initialize Terraform**:
```bash
terraform init
```

3. **Set GitHub token**:
```bash
export TF_VAR_github_token="your_github_token_here"
```

4. **Plan the deployment**:
```bash
AWS_PROFILE=bongaquino terraform plan
```

5. **Apply the configuration**:
```bash
AWS_PROFILE=bongaquino terraform apply
```

### Environment-Specific Configuration

#### UAT Environment (`envs/uat/terraform.tfvars`)
```hcl
app_name         = "bongaquino-web-uat"
branch_name      = "main"
vite_environment = "production"
```

#### Staging Environment (`envs/staging/terraform.tfvars`)
```hcl
app_name         = "bongaquino-web-staging"
branch_name      = "staging"
vite_environment = "staging"
```

#### Production Environment (`envs/prod/terraform.tfvars`)
```hcl
app_name         = "bongaquino-web-prod"
branch_name      = "main"
vite_environment = "production"
```

## Input Variables

### Basic Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `ap-southeast-1` | AWS region for deployment |
| `app_name` | string | - | Name of the Amplify app |
<<<<<<< HEAD
| `repository` | string | `https://github.com/bongaquino/bongaquino-web` | GitHub repository URL |
=======
| `repository` | string | `https://github.com/bongaquino-tech/bongaquino-web` | GitHub repository URL |
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
| `github_token` | string | - | GitHub personal access token (sensitive) |

### Branch Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `branch_name` | string | `main` | Git branch to deploy |
| `branch_stage` | string | `PRODUCTION` | Amplify branch stage |
| `vite_environment` | string | - | Vite environment variable value |

### Domain Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `domain_name` | string | `""` | Custom domain name (optional) |
| `api_url` | string | - | Backend API URL for the environment |

### Tagging & Naming
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | string | `staging` | Environment name for tagging |
| `project` | string | `bongaquino` | Project name for tagging |
| `name_prefix` | string | - | Prefix for resource names |
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `amplify_app_id` | The ID of the Amplify app |
| `amplify_app_arn` | The ARN of the Amplify app |
| `amplify_app_name` | The name of the Amplify app |
| `branch_name` | The deployed branch name |
| `application_url` | The URL where the application is deployed |
| `amplify_console_url` | URL to the Amplify console for management |
| `domain_association_status` | Status of custom domain association (if configured) |

## Performance Optimization

### CDN Configuration
- **Global Distribution**: Automatic CloudFront CDN deployment
- **Edge Caching**: Static assets cached at edge locations worldwide
- **Compression**: Automatic gzip compression for supported file types
- **Cache Control**: Optimized cache headers for different file types

### Build Optimization
- **PNPM Caching**: Efficient dependency caching across builds
- **Parallel Processing**: Concurrent build processes where possible
- **Asset Optimization**: Automatic asset minification and optimization
- **Bundle Splitting**: Code splitting for optimal loading performance

## Security Features

### Access Control
- **GitHub Token Security**: Sensitive token handling with encryption
- **Branch Protection**: Configurable branch access controls
- **Basic Authentication**: Optional password protection for branches
- **Custom Headers**: Configurable security headers

### SPA Routing Configuration
```javascript
// Custom routing rule for single-page applications
{
  source: "/<*>",
  target: "/index.html", 
  status: "404-200"
}
```

### Security Headers
- **Content Security Policy**: Configurable CSP headers
- **HTTPS Enforcement**: Automatic HTTPS redirects
- **HSTS**: HTTP Strict Transport Security
- **X-Frame-Options**: Clickjacking protection

## Monitoring & Logging

### Build Monitoring
- **Build Status**: Real-time build status monitoring
- **Build Logs**: Detailed build output and error logs
- **Performance Metrics**: Build time and deployment metrics
- **Alerts**: Configurable alerts for build failures

### Application Monitoring
- **Access Logs**: CloudFront access logs for traffic analysis
- **Error Tracking**: 4xx/5xx error monitoring
- **Performance Monitoring**: Core web vitals and load times
- **Custom Metrics**: Application-specific metrics

## Custom Domain Configuration

### DNS Setup
```hcl
# Custom domain with subdomain support
resource "aws_amplify_domain_association" "main" {
  app_id      = aws_amplify_app.main.id
  domain_name = "example.com"
  
  sub_domain {
    branch_name = "staging"
    prefix      = "app-staging"
  }
  
  sub_domain {
    branch_name = "main"
    prefix      = "app"
  }
}
```

### SSL Certificate
- **Automatic SSL**: AWS-managed SSL certificates
- **Certificate Renewal**: Automatic certificate renewal
- **Multi-Domain Support**: Single certificate for multiple subdomains

## Environment Management

### Branch Strategies
- **Feature Branches**: Automatic preview deployments
- **Environment Branches**: Dedicated branches per environment
- **Main Branch**: Production deployments
- **Pull Request Previews**: Optional PR preview deployments

### Environment Variables
```hcl
environment_variables = {
  VITE_ENVIRONMENT = var.vite_environment
  VITE_API_URL     = var.api_url
  VITE_APP_VERSION = var.app_version
}
```

## Cost Optimization

### Pricing Components
- **Build Minutes**: Charged per build minute used
- **Storage**: Static file storage costs
- **Data Transfer**: CDN data transfer costs
- **Custom Domains**: Additional domain association costs

### Cost Management
- **Build Optimization**: Efficient builds reduce minute usage
- **Caching Strategy**: Proper caching reduces data transfer
- **Branch Management**: Limit concurrent branches
- **Resource Monitoring**: Track usage and costs

## Troubleshooting

### Build Issues
1. **Node.js Version**: Ensure compatible Node.js version
2. **Dependency Issues**: Check package.json and lock files
3. **Build Scripts**: Verify build commands are correct
4. **Environment Variables**: Confirm all required variables are set

### Deployment Issues
1. **GitHub Permissions**: Verify token has repository access
2. **Branch Existence**: Ensure branch exists in repository
3. **Webhook Configuration**: Check webhook triggers
4. **Domain Issues**: Verify DNS configuration for custom domains

### Performance Issues
1. **Build Time**: Optimize dependencies and build process
2. **Bundle Size**: Analyze and optimize bundle sizes
3. **CDN Performance**: Check CloudFront distribution status
4. **Cache Configuration**: Verify cache headers and policies

### Common Commands
```bash
# Check app status
aws amplify get-app --app-id d3qql0lsyaps7f --profile bongaquino

# List build jobs
aws amplify list-jobs --app-id d3qql0lsyaps7f --branch-name staging --profile bongaquino

# Get build logs
aws amplify get-job --app-id d3qql0lsyaps7f --branch-name staging --job-id <job-id> --profile bongaquino

# Start manual deployment
aws amplify start-job --app-id d3qql0lsyaps7f --branch-name staging --job-type RELEASE --profile bongaquino
```

## Best Practices

1. **Use Environment Variables**: Store configuration in environment variables
2. **Optimize Builds**: Use caching and minimize build times
3. **Security**: Rotate GitHub tokens regularly and use least privilege
4. **Monitoring**: Set up alerts for build failures and performance issues
5. **Testing**: Use branch previews for testing before production
6. **Documentation**: Document environment-specific configurations
7. **Backup**: Export configurations for disaster recovery

## Dependencies

- **GitHub Repository**: Source code repository
- **Route53**: For custom domain DNS management
- **ACM**: For SSL certificate management (with custom domains)
- **CloudFront**: CDN distribution (automatically managed)

## Integration with Other Modules

- **API Gateway**: Backend API integration
- **Route53**: DNS and domain management
- **ACM**: SSL certificate provisioning
- **CloudWatch**: Monitoring and alerting

## Maintenance

- **Regular Updates**: Keep Amplify platform and build tools updated
- **Security Reviews**: Regular security audits and token rotation
- **Performance Monitoring**: Monitor and optimize build and runtime performance
- **Cost Reviews**: Regular cost analysis and optimization
- **Documentation**: Keep environment documentation current

## Support

For issues related to:
- **Build Failures**: Check build logs in Amplify console
- **Domain Issues**: Verify DNS configuration and certificate status
- **Performance**: Analyze CloudFront metrics and build times
- **Security**: Review access controls and security headers
- **Cost**: Monitor usage patterns and optimize accordingly 