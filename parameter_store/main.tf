terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# Standard parameters
resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameters

  name  = "/koneksi/${local.environment}/${each.key}"
  type  = "String"
  value = each.value

  tags = local.common_tags
}

# Secure parameters
resource "aws_ssm_parameter" "secure_parameters" {
  for_each = var.secure_parameters

  name  = "/koneksi/${local.environment}/${each.key}"
  type  = "SecureString"
  value = each.value

  tags = local.common_tags
} 