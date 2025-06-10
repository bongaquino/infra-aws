variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "domain_name" {
  description = "The domain name for the Route53 zone"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "a_records" {
  description = "Map of A records to create"
  type = map(object({
    name    = string
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "cname_records" {
  description = "Map of CNAME records to create"
  type = map(object({
    name   = string
    ttl    = number
    record = string
  }))
  default = {}
}

variable "mx_records" {
  description = "Map of MX records to create"
  type = map(object({
    name    = string
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "txt_records" {
  description = "Map of TXT records to create"
  type = map(object({
    name    = string
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "ns_records" {
  description = "Map of NS records to create"
  type = map(object({
    name    = string
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "alias_records" {
  description = "Map of alias records to create"
  type = map(object({
    name                   = string
    alias_name            = string
    alias_zone_id         = string
    evaluate_target_health = bool
  }))
  default = {}
}

variable "health_checks" {
  description = "Map of health checks to create"
  type = map(object({
    fqdn              = string
    port              = number
    type              = string
    resource_path     = string
    failure_threshold = number
    request_interval  = number
  }))
  default = {}
}

variable "failover_records" {
  description = "Map of failover records to create"
  type = map(object({
    name            = string
    type            = string
    ttl             = number
    set_identifier  = string
    health_check_id = string
    failover_type   = string
    records         = list(string)
  }))
  default = {}
}

variable "weighted_records" {
  description = "Map of weighted records to create"
  type = map(object({
    name           = string
    type           = string
    ttl            = number
    set_identifier = string
    weight         = number
    records        = list(string)
  }))
  default = {}
}

variable "latency_records" {
  description = "Map of latency records to create"
  type = map(object({
    name           = string
    type           = string
    ttl            = number
    set_identifier = string
    region         = string
    records        = list(string)
  }))
  default = {}
}

variable "geolocation_records" {
  description = "Map of geolocation records to create"
  type = map(object({
    name           = string
    type           = string
    ttl            = number
    set_identifier = string
    continent      = optional(string)
    country        = optional(string)
    subdivision    = optional(string)
    records        = list(string)
  }))
  default = {}
}

variable "amplify_domain_name" {
  description = "Domain name for the Amplify app"
  type        = string
}

variable "amplify_domain_target" {
  description = "Target domain name for the Amplify app"
  type        = string
}

variable "amplify_hosted_zone_id" {
  description = "Hosted zone ID for Amplify domains"
  type        = string
  default     = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "staging"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 