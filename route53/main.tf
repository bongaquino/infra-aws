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
# Route53 Hosted Zone
# =============================================================================
resource "aws_route53_zone" "main" {
  name = "example.com"
  tags = {
    Name = "bongaquino-zone"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# MX Record
# =============================================================================
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "MX"
  ttl     = 300
  records = ["0 bongaquino-co-kr.mail.protection.outlook.com."]
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# TXT Records
# =============================================================================
resource "aws_route53_record" "txt_ms" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "TXT"
  ttl     = 120
  records = ["MS=ms62474739 _globalsign-domain-verification=ZP-vTECIFv7iE3MUd-yPRvNCiL8OWfyFTB-YinM08S"]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "txt_dkim" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "20250604040914pm._domainkey.example.com"
  type    = "TXT"
  ttl     = 300
  records = ["k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDCsDAsE41iUNu31DwH9xTX6kcFuKvaUllZ3mp5A1dEiSnJs23HoT0TLzFY9bs/P9iMnY6jtRzhSTOFFBAX+PydIOWIm0AS7Bf3uA74NWUs8ZoXiHhLYgEKMxtxmJJONa5gfMHLzWrmR+tpyy/qNElwnCV1SRnG+cp1x+3+4NiE0QIDAQAB"]
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# CNAME Records
# =============================================================================
resource "aws_route53_record" "autodiscover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "autodiscover.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["autodiscover.outlook.com."]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "pm_bounces" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "pm-bounces.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["pm.mtasv.net."]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["balancer.wixdns.net."]
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# A Records
# =============================================================================
resource "aws_route53_record" "gateway" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "gateway.example.com"
  type    = "A"
  ttl     = 300
  records = ["27.255.70.17"]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "ipfs" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "ipfs.example.com"
  type    = "A"
  ttl     = 300
  records = ["27.255.70.17"]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "staging" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging.example.com"
  type    = "A"
  ttl     = 300
  records = ["52.77.36.120"]
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Alias Records (Amplify)
# =============================================================================
resource "aws_route53_record" "amplify_main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app-staging.example.com"
  type    = "A"
  alias {
    name                   = "d1numm9pbccz2w.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "amplify_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.app-staging.example.com"
  type    = "A"
  alias {
    name                   = "d1234abcd.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Health Checks
# =============================================================================
resource "aws_route53_health_check" "main" {
  for_each = var.health_checks
  fqdn              = each.value.fqdn
  port              = each.value.port
  type              = each.value.type
  resource_path     = each.value.resource_path
  failure_threshold = each.value.failure_threshold
  request_interval  = each.value.request_interval
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "uat" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "uat.example.com"
  type    = "A"
  alias {
    name                   = "dualstack.bongaquino-uat-alb-630040688.ap-southeast-1.elb.amazonaws.com."
    zone_id                = "Z1LMS91P8CMLE5"
    evaluate_target_health = false
  }
  lifecycle {
    prevent_destroy = true
  }
} 