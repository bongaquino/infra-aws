variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "domain_name" {
  description = "The domain name for the Route53 zone"
  type        = string
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

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
} 