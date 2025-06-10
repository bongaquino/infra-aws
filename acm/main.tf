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
# ACM Certificate
# =============================================================================
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-certificate"
  })
}

# =============================================================================
# ACM Certificate Validation
# =============================================================================
resource "aws_acm_certificate_validation" "main" {
  count                   = var.validation_method == "DNS" ? 1 : 0
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# =============================================================================
# Route53 Validation Records
# =============================================================================
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "certificate_expiration" {
  alarm_name          = "${var.name_prefix}-certificate-expiration"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period             = "86400"  # 24 hours
  statistic          = "Minimum"
  threshold          = "30"
  alarm_description  = "This metric monitors ACM certificate expiration"
  
  dimensions = {
    CertificateArn = aws_acm_certificate.main.arn
  }
  
  tags = var.tags
} 