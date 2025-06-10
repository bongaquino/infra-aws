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
# IAM Role
# =============================================================================
resource "aws_iam_role" "main" {
  name = "${var.name_prefix}-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.service_principal
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-role"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# IAM Policy
# =============================================================================
resource "aws_iam_policy" "main" {
  name        = "${var.name_prefix}-policy"
  description = "IAM policy for ${var.name_prefix}"
  policy      = var.policy_document
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-policy"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# IAM Role Policy Attachment
# =============================================================================
resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

# =============================================================================
# IAM Instance Profile
# =============================================================================
resource "aws_iam_instance_profile" "main" {
  count = var.create_instance_profile ? 1 : 0
  name  = "${var.name_prefix}-instance-profile"
  role  = aws_iam_role.main.name
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance-profile"
  })
}

# =============================================================================
# IAM User
# =============================================================================
resource "aws_iam_user" "main" {
  count = var.create_user ? 1 : 0
  name  = "${var.name_prefix}-user"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-user"
  })
}

# =============================================================================
# IAM User Policy Attachment
# =============================================================================
resource "aws_iam_user_policy_attachment" "main" {
  count      = var.create_user ? 1 : 0
  user       = aws_iam_user.main[0].name
  policy_arn = aws_iam_policy.main.arn
}

# =============================================================================
# IAM Access Key
# =============================================================================
resource "aws_iam_access_key" "main" {
  count = var.create_user && var.create_access_key ? 1 : 0
  user  = aws_iam_user.main[0].name
}

# =============================================================================
# IAM Group
# =============================================================================
resource "aws_iam_group" "main" {
  count = var.create_group ? 1 : 0
  name  = "${var.name_prefix}-group"
}

# =============================================================================
# IAM Group Policy Attachment
# =============================================================================
resource "aws_iam_group_policy_attachment" "main" {
  count      = var.create_group ? 1 : 0
  group      = aws_iam_group.main[0].name
  policy_arn = aws_iam_policy.main.arn
}

# =============================================================================
# IAM Group Membership
# =============================================================================
resource "aws_iam_user_group_membership" "main" {
  count  = var.create_user && var.create_group ? 1 : 0
  user   = aws_iam_user.main[0].name
  groups = [aws_iam_group.main[0].name]
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "failed_login_attempts" {
  count               = var.create_user ? 1 : 0
  alarm_name          = "${var.name_prefix}-failed-login-attempts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedLoginAttempts"
  namespace           = "AWS/IAM"
  period             = "300"
  statistic          = "Sum"
  threshold          = "3"
  alarm_description  = "This metric monitors IAM failed login attempts"
  
  dimensions = {
    UserName = aws_iam_user.main[0].name
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "access_key_usage" {
  count               = var.create_user && var.create_access_key ? 1 : 0
  alarm_name          = "${var.name_prefix}-access-key-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AccessKeyUsage"
  namespace           = "AWS/IAM"
  period             = "300"
  statistic          = "Sum"
  threshold          = "100"
  alarm_description  = "This metric monitors IAM access key usage"
  
  dimensions = {
    UserName = aws_iam_user.main[0].name
  }
  
  tags = var.tags
} 