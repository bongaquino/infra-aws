# Staging CodePipeline for bongaquino-backend to EC2

provider "aws" {
  region = "ap-southeast-1"
}

locals {
  env = "staging"
  github_repo = "bongaquino/bongaquino-backend"  
  github_branch = "staging"
  ec2_instance_ip = "52.77.36.120"
}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "bongaquino-${local.env}-cd-artifacts"
  force_destroy = true
  tags = {
    Project     = "bongaquino"
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "bongaquino-${local.env}-cd-pipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# Custom policy for CodeStar connections
resource "aws_iam_policy" "codepipeline_codestar_policy" {
  name        = "bongaquino-${local.env}-cd-pipeline-codestar-policy"
  description = "Allow CodePipeline to use CodeStar connections"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codestar_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_codestar_policy.arn
}

# Custom policy for CodeBuild access
resource "aws_iam_policy" "codepipeline_codebuild_policy" {
  name        = "bongaquino-${local.env}-cd-pipeline-codebuild-policy"
  description = "Allow CodePipeline to start CodeBuild projects"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetProjects"
        ],
        Resource = aws_codebuild_project.staging_deploy.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_codebuild_policy.arn
}

# IAM Role for CodeBuild (SSH deployment to EC2)
resource "aws_iam_role" "codebuild_role" {
  name = "bongaquino-${local.env}-cd-build-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

# SSM policy for CodeBuild to access SSH key
resource "aws_iam_policy" "codebuild_ssm_policy" {
  name        = "bongaquino-${local.env}-cd-build-ssm-policy"
  description = "Allow CodeBuild to get SSH key from Parameter Store"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = [
          "arn:aws:ssm:ap-southeast-1:*:parameter/bongaquino/staging/ssh-key",
          "arn:aws:ssm:ap-southeast-1:*:parameter/bongaquino/staging/github-token"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_ssm_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_ssm_policy.arn
}

# CodeBuild project for EC2 deployment  
resource "aws_codebuild_project" "staging_deploy" {
  name          = "bongaquino-${local.env}-deploy"
  description   = "Deploy bongaquino-backend to EC2 instance via SSH"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    environment_variable {
      name  = "EC2_INSTANCE_IP"
      value = local.ec2_instance_ip
    }
    environment_variable {
      name  = "GITHUB_REPO"
      value = local.github_repo
    }
    environment_variable {
      name  = "GITHUB_BRANCH"
      value = local.github_branch
    }
  }
  source {
    type = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }
  tags = {
    Project     = "bongaquino"
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

# CodePipeline for staging EC2 deployment
resource "aws_codepipeline" "staging_pipeline" {
  name     = "bongaquino-${local.env}-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        ConnectionArn     = aws_codestarconnections_connection.github.arn
        FullRepositoryId  = local.github_repo
        BranchName        = local.github_branch
        DetectChanges     = "true"
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["DeployOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.staging_deploy.name
      }
      version = "1"
    }
  }
}

# GitHub connection
resource "aws_codestarconnections_connection" "github" {
  name          = "bongaquino-staging-github"
  provider_type = "GitHub"
}

# IAM policies for S3 access
resource "aws_iam_policy" "codepipeline_s3_policy" {
  name        = "bongaquino-${local.env}-cd-pipeline-s3-policy"
  description = "Allow CodePipeline to access its artifact bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_s3_policy.arn
}

# CloudWatch Logs policy for CodeBuild
resource "aws_iam_policy" "codebuild_logs_policy" {
  name        = "bongaquino-${local.env}-cd-build-logs-policy"
  description = "Allow CodeBuild to write to CloudWatch Logs"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_logs_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_logs_policy.arn
}

# S3 policy for CodeBuild
resource "aws_iam_policy" "codebuild_s3_policy" {
  name        = "bongaquino-${local.env}-cd-build-s3-policy"
  description = "Allow CodeBuild to access S3 artifacts"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion"
        ],
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_s3_policy.arn
}

# Outputs
output "pipeline_arn" {
  description = "ARN of the staging deployment pipeline"
  value       = aws_codepipeline.staging_pipeline.arn
}

output "github_connection_arn" {
  description = "ARN of the GitHub connection"
  value       = aws_codestarconnections_connection.github.arn
}

output "github_connection_status" {
  description = "Status of the GitHub connection"
  value       = aws_codestarconnections_connection.github.connection_status
} 