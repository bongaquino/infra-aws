# =============================================================================
# Terraform Configuration
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# =============================================================================
# Amplify App
# =============================================================================
resource "aws_amplify_app" "main" {
  name                     = var.app_name
  repository               = var.repository
  access_token             = var.github_token
  enable_branch_auto_build = true
  
  # Build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT
  
  # Environment variables
  environment_variables = {
    REACT_APP_API_URL = var.api_url
    NODE_ENV          = var.environment
  }
  
  # Custom headers
  custom_headers = <<-EOT
    customHeaders:
      - pattern: '**/*'
        headers:
          - key: 'Strict-Transport-Security'
            value: 'max-age=31536000; includeSubDomains'
          - key: 'X-Frame-Options'
            value: 'SAMEORIGIN'
          - key: 'X-XSS-Protection'
            value: '1; mode=block'
          - key: 'X-Content-Type-Options'
            value: 'nosniff'
  EOT
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-amplify-app"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Amplify Branch
# =============================================================================
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = var.branch_name
  
  enable_auto_build = true
  
  framework = "React"
  
  environment_variables = {
    REACT_APP_API_URL = var.api_url
    NODE_ENV          = var.environment
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-amplify-branch"
  })
}

# =============================================================================
# Amplify Domain
# =============================================================================
resource "aws_amplify_domain_association" "main" {
  app_id      = aws_amplify_app.main.id
  domain_name = var.domain_name
  
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
  
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }
}

# =============================================================================
# Amplify Webhook
# =============================================================================
resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Webhook for main branch"
} 