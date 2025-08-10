# =============================================================================
# Amplify App Configuration for Staging
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    key            = "amplify/staging/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "bongaquino-terraform-locks"
  }
}

provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project     = "bongaquino"
      Environment = "staging"
      ManagedBy   = "terraform"
      Component   = "amplify"
    }
  }
}

module "amplify" {
  source = "../../"

  app_name       = var.app_name
  repository_url = var.repository_url
  github_token   = var.github_token
  environment    = var.environment

  # Enable auto-build and branch management
  enable_auto_build           = true
  enable_branch_auto_deletion = true

  # Environment variables
  environment_variables = {
    NODE_ENV         = "staging"
    VITE_ENVIRONMENT = "staging"
  }

  tags = {
    Project     = "bongaquino"
    Environment = "staging"
    ManagedBy   = "terraform"
    Component   = "amplify"
    Role        = "web-app"
  }
}
 