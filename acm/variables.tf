variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "domain_name" {
  description = "The primary domain name for the ACM certificate."
  type        = string
}

variable "subject_alternative_names" {
  description = "A list of subject alternative names for the ACM certificate."
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Which method to use for validation. DNS or EMAIL"
  type        = string
  default     = "DNS"
}