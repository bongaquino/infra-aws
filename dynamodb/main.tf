terraform {
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

# DynamoDB Table
resource "aws_dynamodb_table" "koneksi_table" {
  name                        = "${var.project}-${var.environment}-${var.table_name}"
  billing_mode               = var.billing_mode
  hash_key                   = var.hash_key
  deletion_protection_enabled = var.environment == "prod" ? true : false
  
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = var.enable_server_side_encryption
  }

  tags = {
    Name        = "${var.project}-${var.environment}-dynamodb"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
} 