terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"  # Singapore region, adjust as needed
}

# DynamoDB Table
resource "aws_dynamodb_table" "koneksi_table" {
  name           = "koneksi-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "koneksi-dynamodb"
  }
} 