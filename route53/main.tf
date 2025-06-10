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
# Route53 Zone
# =============================================================================
resource "aws_route53_zone" "main" {
  name = var.domain_name
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-zone"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Route53 A Records
# =============================================================================
resource "aws_route53_record" "staging" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging.koneksi.co.kr"
  type    = "A"
  ttl     = 300
  records = ["52.77.36.120"]
}

resource "aws_route53_record" "ipfs" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "ipfs.koneksi.co.kr"
  type    = "A"
  ttl     = 300
  records = ["211.239.117.217"]
}

resource "aws_route53_record" "gateway" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "gateway.koneksi.co.kr"
  type    = "A"
  ttl     = 300
  records = ["211.239.117.217"]
}

# =============================================================================
# Route53 CNAME Records
# =============================================================================
resource "aws_route53_record" "autodiscover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "autodiscover.koneksi.co.kr"
  type    = "CNAME"
  ttl     = 300
  records = ["autodiscover.outlook.com."]
}

resource "aws_route53_record" "pm_bounces" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "pm-bounces.koneksi.co.kr"
  type    = "CNAME"
  ttl     = 300
  records = ["pm.mtasv.net."]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.koneksi.co.kr"
  type    = "CNAME"
  ttl     = 300
  records = ["balancer.wixdns.net."]
}

# =============================================================================
# Route53 MX Records
# =============================================================================
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "koneksi.co.kr"
  type    = "MX"
  ttl     = 300
  records = ["0 koneksi-co-kr.mail.protection.outlook.com."]
}

# =============================================================================
# Route53 TXT Records
# =============================================================================
resource "aws_route53_record" "txt_ms" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "koneksi.co.kr"
  type    = "TXT"
  ttl     = 300
  records = ["MS=ms62474739"]
}

resource "aws_route53_record" "txt_dkim" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "20250604040914pm._domainkey.koneksi.co.kr"
  type    = "TXT"
  ttl     = 300
  records = ["k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDCsDAsE41iUNu31DwH9xTX6kcFuKvaUllZ3mp5A1dEiSnJs23HoT0TLzFY9bs/P9iMnY6jtRzhSTOFFBAX+PydIOWIm0AS7Bf3uA74NWUs8ZoXiHhLYgEKMxtxmJJONa5gfMHLzWrmR+tpyy/qNElwnCV1SRnG+cp1x+3+4NiE0QIDAQAB"]
}

# =============================================================================
# Route53 Alias Records (Amplify)
# =============================================================================
resource "aws_route53_record" "amplify_main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app-staging.koneksi.co.kr"
  type    = "A"
  alias {
    name                   = "d1234abcd.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "amplify_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.app-staging.koneksi.co.kr"
  type    = "A"
  alias {
    name                   = "d1234abcd.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
}

# =============================================================================
# Route53 Health Checks
# =============================================================================
resource "aws_route53_health_check" "main" {
  for_each = var.health_checks
  
  fqdn              = each.value.fqdn
  port              = each.value.port
  type              = each.value.type
  resource_path     = each.value.resource_path
  failure_threshold = each.value.failure_threshold
  request_interval  = each.value.request_interval
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-health-check-${each.key}"
  })
}

# =============================================================================
# Route53 Failover Records
# =============================================================================
resource "aws_route53_record" "failover" {
  for_each = var.failover_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  
  set_identifier = each.value.set_identifier
  health_check_id = each.value.health_check_id
  
  failover_routing_policy {
    type = each.value.failover_type
  }
  
  records = each.value.records
}

# =============================================================================
# Route53 Weighted Records
# =============================================================================
resource "aws_route53_record" "weighted" {
  for_each = var.weighted_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  
  set_identifier = each.value.set_identifier
  
  weighted_routing_policy {
    weight = each.value.weight
  }
  
  records = each.value.records
  
  allow_overwrite = true
}

# =============================================================================
# Route53 Latency Records
# =============================================================================
resource "aws_route53_record" "latency" {
  for_each = var.latency_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  
  set_identifier = each.value.set_identifier
  
  latency_routing_policy {
    region = each.value.region
  }
  
  records = each.value.records
  
  allow_overwrite = true
}

# =============================================================================
# Route53 Geolocation Records
# =============================================================================
resource "aws_route53_record" "geolocation" {
  for_each = var.geolocation_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  
  set_identifier = each.value.set_identifier
  
  geolocation_routing_policy {
    continent   = each.value.continent
    country     = each.value.country
    subdivision = each.value.subdivision
  }
  
  records = each.value.records
} 