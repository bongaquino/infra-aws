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
# CloudFront Distribution
# =============================================================================
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.price_class
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment
  
  aliases = var.aliases
  
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = var.origin_id
    
    forwarded_values {
      query_string = var.forward_query_string
      cookies {
        forward = var.forward_cookies
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true
  }
  
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      min_ttl                = ordered_cache_behavior.value.min_ttl
      default_ttl            = ordered_cache_behavior.value.default_ttl
      max_ttl                = ordered_cache_behavior.value.max_ttl
      compress               = ordered_cache_behavior.value.compress
      
      forwarded_values {
        query_string = ordered_cache_behavior.value.forward_query_string
        cookies {
          forward = ordered_cache_behavior.value.forward_cookies
        }
      }
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-distribution"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.name_prefix}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period             = "300"
  statistic          = "Average"
  threshold          = "1"
  alarm_description  = "This metric monitors CloudFront 5xx error rate"
  
  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
    Region         = "Global"
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "request_count" {
  alarm_name          = "${var.name_prefix}-request-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Requests"
  namespace           = "AWS/CloudFront"
  period             = "300"
  statistic          = "Sum"
  threshold          = "1000"
  alarm_description  = "This metric monitors CloudFront request count"
  
  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
    Region         = "Global"
  }
  
  tags = var.tags
} 