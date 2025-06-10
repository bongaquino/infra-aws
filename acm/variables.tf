variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "domain_name" {
  description = "The domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names to be included in the certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Which method to use for validation. DNS or EMAIL"
  type        = string
  default     = "DNS"
}

variable "route53_zone_id" {
  description = "The ID of the Route53 hosted zone for DNS validation"
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