# AWS Amplify Module

This module creates an AWS Amplify app for hosting the Koneksi web application. It provides:
- GitHub repository integration
- Automatic branch builds and deployments
- Environment-specific configurations
- Custom domain support
- Build caching and optimization

## Prerequisites

1. GitHub Personal Access Token with repo access
2. Domain name registered in Route 53 (or another DNS provider)
3. AWS credentials configured
4. Node.js and pnpm installed locally for development

## Module Structure

```
amplify/
├── modules/
│   └── app/
│       ├── main.tf           # Main Amplify configuration
│       ├── outputs.tf        # Output definitions
│       ├── variables.tf      # Variable definitions
│       ├── README.md         # This documentation
│       └── envs/
│           └── staging/      # Staging environment
│               ├── main.tf   # Staging-specific configuration
│               ├── outputs.tf
│               ├── variables.tf
│               └── terraform.tfvars
```

## Build Configuration

The module uses pnpm for package management and builds. The build process includes:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - git checkout staging
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

## Environment Variables

The following environment variables are configured:

- `NODE_ENV`: Set to the environment name (staging, uat, prod)
- `VITE_ENVIRONMENT`: Set to match NODE_ENV
- Additional variables can be added in the module configuration

## Usage

```hcl
module "amplify" {
  source = "./modules/app"

  app_name       = "koneksi-web-staging"
  repository_url = "https://github.com/koneksi-tech/koneksi-web"
  github_token   = var.github_token
  environment    = "staging"
  domain_name    = var.domain_name

  tags = {
    Project     = "koneksi"
    Environment = "staging"
    ManagedBy   = "terraform"
    Component   = "amplify"
    Role        = "web-app"
  }
}
```

## Required Variables

- `app_name`: Name of the Amplify app (e.g., koneksi-web-staging)
- `repository_url`: URL of the GitHub repository
- `github_token`: GitHub personal access token
- `environment`: Environment name (staging, uat, prod)
- `domain_name`: Domain name for the Amplify app

## Optional Variables

- `tags`: Map of tags to apply to all resources
- `enable_auto_build`: Enable automatic builds on push (default: true)
- `enable_branch_auto_deletion`: Enable automatic branch deletion (default: true)

## Outputs

- `app_id`: ID of the created Amplify app
- `app_arn`: ARN of the created Amplify app
- `branch_name`: Name of the created branch
- `default_domain`: Default domain of the app

## Deployment Process

1. **Initial Setup**:
   ```bash
   cd amplify/modules/app/envs/staging
   terraform init
   ```

2. **Apply Configuration**:
   ```bash
   terraform apply
   ```

3. **Monitor Build**:
   ```bash
   aws amplify list-jobs --app-id <app_id> --branch-name staging
   ```

4. **Access Application**:
   - Default domain: `<app_id>.amplifyapp.com`
   - Custom domain: `<domain_name>` (if configured)

## Maintenance

- Regularly update the build configuration as needed
- Monitor build logs for any issues
- Keep environment variables up to date
- Review and update security settings
- Monitor build performance and cache usage

## Troubleshooting

1. **Build Failures**:
   - Check build logs in AWS Amplify Console
   - Verify environment variables
   - Check pnpm and Node.js versions

2. **Deployment Issues**:
   - Verify GitHub repository access
   - Check branch protection rules
   - Verify domain configuration

3. **Performance Issues**:
   - Review build cache configuration
   - Check build timeouts
   - Optimize build commands

## Security

- GitHub token is stored securely
- Environment variables are encrypted
- Branch protection rules are enforced
- Custom domains use HTTPS
- Regular security updates

## Contributing

1. Create a new branch for changes
2. Update documentation as needed
3. Test changes in staging
4. Create pull request
5. Get team approval
6. Merge to staging first
7. After testing, merge to main 