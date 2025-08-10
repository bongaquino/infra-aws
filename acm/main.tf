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

provider "aws" {
  region = "us-east-1"  # Required for ACM certificates used with CloudFront
  alias  = "virginia"
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_route53_zone" "main" {
  name = "example.com"
}

# =============================================================================
# ACM Certificate
# =============================================================================
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }

  tags = {
    Name      = "bongaquino-cert"
    ManagedBy = "terraform"
  }
} 