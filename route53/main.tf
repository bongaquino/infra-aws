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
}

# =============================================================================
# Route53 Records
# =============================================================================
resource "aws_route53_record" "a" {
  for_each = var.a_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "A"
  ttl     = each.value.ttl
  
  records = each.value.records
}

resource "aws_route53_record" "cname" {
  for_each = var.cname_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "CNAME"
  ttl     = each.value.ttl
  
  records = [each.value.record]
}

resource "aws_route53_record" "mx" {
  for_each = var.mx_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "MX"
  ttl     = each.value.ttl
  
  records = each.value.records
}

resource "aws_route53_record" "txt" {
  for_each = var.txt_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "TXT"
  ttl     = each.value.ttl
  
  records = each.value.records
}

resource "aws_route53_record" "ns" {
  for_each = var.ns_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "NS"
  ttl     = each.value.ttl
  
  records = each.value.records
}

resource "aws_route53_record" "alias" {
  for_each = var.alias_records
  
  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "A"
  
  alias {
    name                   = each.value.alias_name
    zone_id                = each.value.alias_zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}

# =============================================================================
# Amplify Domain Records
# =============================================================================
resource "aws_route53_record" "amplify_main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.amplify_domain_name
  type    = "A"
  
  alias {
    name                   = var.amplify_domain_target
    zone_id                = var.amplify_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "amplify_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.amplify_domain_name}"
  type    = "A"
  
  alias {
    name                   = var.amplify_domain_target
    zone_id                = var.amplify_hosted_zone_id
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
  weight         = each.value.weight
  
  records = each.value.records
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
  region         = each.value.region
  
  records = each.value.records
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