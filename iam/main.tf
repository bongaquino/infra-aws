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

# IAM Group for Developers
resource "aws_iam_group" "developers" {
  name = "ardata-developers"
  path = "/users/"
}

# IAM Group for DevOps
resource "aws_iam_group" "devops" {
  name = "ardata-devops"
  path = "/users/"
}

# IAM Policy for Developer Access
resource "aws_iam_policy" "developer_policy" {
  name        = "ardata-developer-policy"
  description = "Policy for ARData developers"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "elasticache:Describe*",
          "elasticache:List*",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for DevOps Access
resource "aws_iam_policy" "devops_policy" {
  name        = "ardata-devops-policy"
  description = "Policy for ARData DevOps engineers"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "dynamodb:*",
          "elasticache:*",
          "s3:*",
          "iam:GetUser",
          "iam:ListUsers",
          "iam:ListGroups",
          "iam:ListPolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedGroupPolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to groups
resource "aws_iam_group_policy_attachment" "developer_policy_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

resource "aws_iam_group_policy_attachment" "devops_policy_attachment" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devops_policy.arn
}

# IAM Users
resource "aws_iam_user" "users" {
  for_each = local.all_users
  name     = each.value.username
  path     = "/users/"

  tags = {
    Name        = each.value.username
    Project     = var.project
    ManagedBy   = "terraform"
    Department  = each.value.department
    Team        = each.value.team
    Email       = each.value.email
    Role        = each.value.role
  }
}

# Add users to groups
resource "aws_iam_user_group_membership" "user_groups" {
  for_each = local.all_users
  user     = aws_iam_user.users[each.key].name
  groups   = [each.value.department == "devops" ? aws_iam_group.devops.name : aws_iam_group.developers.name]
}

# Create access keys for users
resource "aws_iam_access_key" "user_keys" {
  for_each = local.all_users
  user     = aws_iam_user.users[each.key].name
} 