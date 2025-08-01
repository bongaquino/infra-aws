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
  name                         = var.app_name
  repository                   = var.repository
  access_token                 = var.github_token
  enable_branch_auto_build     = true
  enable_branch_auto_deletion  = false
  enable_basic_auth           = false
  platform                    = "WEB"
  
  # Build settings - using the working pnpm configuration
  build_spec = <<-EOT
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
  EOT
  
  # Environment variables
  environment_variables = {
    VITE_ENVIRONMENT = var.vite_environment
  }
  
  # Custom rules for SPA routing
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404-200"
  }
  
  enable_auto_branch_creation = false
  
  cache_config {
    type = "AMPLIFY_MANAGED_NO_COOKIES"
  }
  
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
  app_id                = aws_amplify_app.main.id
  branch_name           = var.branch_name
  stage                 = var.branch_stage
  display_name          = var.branch_name
  enable_notification   = false
  enable_auto_build     = true
  framework             = "Web"
  enable_basic_auth     = false
  enable_performance_mode = false
  ttl                   = "5"
  enable_pull_request_preview = false
  
  environment_variables = {}
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-amplify-branch"
  })
}

# =============================================================================
# Amplify Domain (Optional - only if domain_name is provided)
# =============================================================================
resource "aws_amplify_domain_association" "main" {
  count       = var.domain_name != "" ? 1 : 0
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
# Amplify Webhook (Optional - only if webhook is needed)
# =============================================================================
# Commented out - staging app has no webhook
# resource "aws_amplify_webhook" "main" {
#   app_id      = aws_amplify_app.main.id
#   branch_name = aws_amplify_branch.main.branch_name
#   description = "Webhook for ${var.branch_name} branch"
# } 