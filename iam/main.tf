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
# IAM Groups
# =============================================================================
resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group" "operations" {
  name = "operations"
}

resource "aws_iam_group" "management" {
  name = "management"
}

resource "aws_iam_group" "bongaquino_developers" {
  name = "bongaquino-developers"
}

# =============================================================================
# IAM Group Policies
# =============================================================================
resource "aws_iam_group_policy_attachment" "developers" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group_policy_attachment" "operations" {
  group      = aws_iam_group.operations.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "management" {
  group      = aws_iam_group.management.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "bongaquino_developers" {
  group      = aws_iam_group.bongaquino_developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# =============================================================================
# Custom IAM Policies
# =============================================================================
resource "aws_iam_policy" "amplify_full_access" {
  name        = "AmplifyFullAccess"
  description = "Provides full access to AWS Amplify"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "amplify:*",
          "amplifybackend:*",
          "amplifyuibuilder:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_parameter_store_rw" {
  name        = "SSMParameterStoreReadWrite"
  description = "Allow read/write access to SSM Parameter Store"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:DescribeParameters",
          "ssm:PutParameter",
          "ssm:DeleteParameter"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = "CloudWatchLogsAccess"
  description = "Allow access to CloudWatch Logs including live tail"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:StartLiveTail",
          "logs:GetLogEvents",
          "logs:DescribeLogGroups",
          "logs:FilterLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/bongaquino-uat:*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/bongaquino-prod:*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/bongaquino-staging:*"
        ]
      }
    ]
  })
}

# =============================================================================
# IAM Users
# =============================================================================
resource "aws_iam_user" "users" {
  for_each = var.users

  name = each.value.username
  
  tags = merge(var.tags, {
    Name        = each.value.username
    Department  = each.value.department
    Team        = each.value.team
    Email       = each.value.email
    Role        = each.value.role
  })
}

# =============================================================================
# IAM User Login Profiles
# =============================================================================
resource "aws_iam_user_login_profile" "user_profiles" {
  for_each = var.users

  user = aws_iam_user.users[each.key].name
  
  # Don't manage password settings to avoid forcing replacement
  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
      password
    ]
  }
}

# =============================================================================
# IAM User Group Memberships
# =============================================================================
resource "aws_iam_user_group_membership" "user_groups" {
  for_each = var.users

  user   = aws_iam_user.users[each.key].name
  groups = [each.value.role == "Developer" ? aws_iam_group.developers.name : 
           each.value.role == "Operations" ? aws_iam_group.operations.name :
           aws_iam_group.management.name]
}

# =============================================================================
# IAM User Policy Attachments
# =============================================================================
resource "aws_iam_user_policy_attachment" "franz_amplify" {
  user       = aws_iam_user.users["franz_egos"].name
  policy_arn = aws_iam_policy.amplify_full_access.arn
}

resource "aws_iam_group_policy_attachment" "developers_ssm_parameter_store" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.ssm_parameter_store_rw.arn
}

resource "aws_iam_group_policy_attachment" "bongaquino_developers_cloudwatch_logs" {
  group      = aws_iam_group.bongaquino_developers.name
  policy_arn = aws_iam_policy.cloudwatch_logs_access.arn
}

# =============================================================================
# IAM Access Keys
# =============================================================================
resource "aws_iam_access_key" "user_keys" {
  for_each = var.users

  user = aws_iam_user.users[each.key].name
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "failed_login_attempts" {
  for_each = var.users

  alarm_name          = "${each.value.username}-failed-login-attempts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedLoginAttempts"
  namespace           = "AWS/IAM"
  period             = "300"
  statistic          = "Sum"
  threshold          = "3"
  alarm_description  = "This metric monitors IAM failed login attempts for ${each.value.username}"
  
  dimensions = {
    UserName = aws_iam_user.users[each.key].name
  }
  
  tags = merge(var.tags, {
    Name = "${each.value.username}-failed-login-attempts"
    User = each.value.username
  })
}

resource "aws_cloudwatch_metric_alarm" "access_key_usage" {
  for_each = var.users

  alarm_name          = "${each.value.username}-access-key-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AccessKeyUsage"
  namespace           = "AWS/IAM"
  period             = "300"
  statistic          = "Sum"
  threshold          = "100"
  alarm_description  = "This metric monitors IAM access key usage for ${each.value.username}"
  
  dimensions = {
    UserName = aws_iam_user.users[each.key].name
  }
  
  tags = merge(var.tags, {
    Name = "${each.value.username}-access-key-usage"
    User = each.value.username
  })
} 