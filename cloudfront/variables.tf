variable "domain_name" {
  description = "The domain name for the CloudFront distribution"
  type        = string
  default     = "app-staging.koneksi.co.kr"
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate"
  type        = string
}

variable "origin_domain" {
  description = "The domain name of the origin (Amplify app)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "price_class" {
  description = "The price class for the CloudFront distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "retain_on_delete" {
  description = "Whether to retain the CloudFront distribution on deletion"
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "Whether to wait for the CloudFront distribution to be deployed"
  type        = bool
  default     = true
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names) for the CloudFront distribution"
  type        = list(string)
}

variable "origin_domain_name" {
  description = "The domain name of the origin"
  type        = string
}

variable "origin_id" {
  description = "A unique identifier for the origin"
  type        = string
}

variable "allowed_methods" {
  description = "Controls which HTTP methods CloudFront processes and forwards to your origin"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "cached_methods" {
  description = "Controls whether CloudFront caches the response to requests using the specified HTTP methods"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "forward_query_string" {
  description = "Indicates whether you want CloudFront to forward query strings to the origin"
  type        = bool
  default     = true
}

variable "forward_cookies" {
  description = "Specifies which cookies to forward to the origin"
  type        = string
  default     = "all"
}

variable "min_ttl" {
  description = "The minimum amount of time that you want objects to stay in CloudFront caches"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "The default amount of time that you want objects to stay in CloudFront caches"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "The maximum amount of time that you want objects to stay in CloudFront caches"
  type        = number
  default     = 86400
}

variable "ordered_cache_behaviors" {
  description = "An ordered list of cache behaviors for the CloudFront distribution"
  type = list(object({
    path_pattern           = string
    allowed_methods        = list(string)
    cached_methods         = list(string)
    target_origin_id       = string
    viewer_protocol_policy = string
    min_ttl                = number
    default_ttl            = number
    max_ttl                = number
    compress               = bool
    forward_query_string   = bool
    forward_cookies        = string
  }))
  default = []
}

variable "geo_restriction_type" {
  description = "The method that you want to use to restrict distribution of your content by country"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "The ISO 3166-1-alpha-2 codes for which you want CloudFront to distribute your content"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the CloudFront distribution"
  type        = string
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

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
} 