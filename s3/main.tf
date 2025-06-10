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
# S3 Bucket
# =============================================================================
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  
  tags = merge(var.tags, {
    Name        = var.bucket_name
    Project     = var.project
    Environment = var.environment
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# S3 Bucket Versioning
# =============================================================================
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# =============================================================================
# S3 Bucket Server-Side Encryption
# =============================================================================
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

# =============================================================================
# S3 Bucket Lifecycle Rules
# =============================================================================
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status
      
      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
      
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}

# =============================================================================
# S3 Bucket Public Access Block
# =============================================================================
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# S3 Bucket CORS Configuration
# =============================================================================
resource "aws_s3_bucket_cors_configuration" "main" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id
  
  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# =============================================================================
# S3 Bucket Policy
# =============================================================================
resource "aws_s3_bucket_policy" "main" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  policy = var.bucket_policy
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  alarm_name          = "${var.project}-${var.environment}-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period             = "86400"  # 24 hours
  statistic          = "Average"
  threshold          = var.bucket_size_threshold
  alarm_description  = "This metric monitors S3 bucket size"
  
  dimensions = {
    BucketName = aws_s3_bucket.main.id
    StorageType = "StandardStorage"
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "number_of_objects" {
  alarm_name          = "${var.project}-${var.environment}-number-of-objects"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period             = "86400"  # 24 hours
  statistic          = "Average"
  threshold          = var.number_of_objects_threshold
  alarm_description  = "This metric monitors S3 number of objects"
  
  dimensions = {
    BucketName = aws_s3_bucket.main.id
    StorageType = "AllStorageTypes"
  }
  
  tags = var.tags
} 