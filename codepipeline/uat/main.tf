# UAT CodePipeline for koneksi-backend

provider "aws" {
  region = "ap-southeast-1"
}

locals {
  env = terraform.workspace
}

# ECR Repository
resource "aws_ecr_repository" "backend" {
  name = "koneksi-${local.env}-backend"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project     = "koneksi"
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "koneksi-${local.env}-codepipeline-artifacts"
  force_destroy = true
  tags = {
    Project     = "koneksi"
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "koneksi-${local.env}-codepipeline-role"
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

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_admin" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "codepipeline_ecr_poweruser" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "codepipeline_ecs_fullaccess" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "koneksi-${local.env}-codebuild-role"
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

resource "aws_iam_role_policy_attachment" "codebuild_ecr_poweruser" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# CodeBuild project
resource "aws_codebuild_project" "backend_build" {
  name          = "koneksi-${local.env}-backend-build"
  description   = "Build and push Docker image for koneksi-backend to ECR"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-southeast-1"
    }
  }
  source {
    type = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }
  tags = {
    Project     = "koneksi"
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}

# CodePipeline
resource "aws_codepipeline" "backend_pipeline" {
  name     = "koneksi-${local.env}-backend-pipeline"
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
        ConnectionArn     = "arn:aws:codestar-connections:ap-southeast-1:985869370256:connection/d089b2df-62f4-46b0-8364-b0eeef3939ec"
        FullRepositoryId  = "koneksi-tech/koneksi-backend"
        BranchName        = "main"
        DetectChanges     = "true"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.backend_build.name
      }
      version = "1"
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildOutput"]
      configuration = {
        ClusterName = "koneksi-${local.env}-cluster"
        ServiceName = "koneksi-${local.env}-service"
        FileName    = "imagedefinitions.json"
      }
      version = "1"
    }
  }
}

resource "aws_codestarconnections_connection" "github" {
  name          = "koneksi-${local.env}-github-connection"
  provider_type = "GitHub"
}

resource "aws_iam_policy" "codepipeline_s3_policy" {
  name        = "koneksi-${local.env}-codepipeline-s3-policy"
  description = "Allow CodePipeline to access its artifact bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::koneksi-${local.env}-codepipeline-artifacts",
          "arn:aws:s3:::koneksi-${local.env}-codepipeline-artifacts/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codepipeline_s3_policy_attach" {
  name       = "koneksi-${local.env}-codepipeline-s3-policy-attach"
  roles      = [aws_iam_role.codepipeline_role.name]
  policy_arn = aws_iam_policy.codepipeline_s3_policy.arn
}

resource "aws_iam_policy" "codebuild_logs_policy" {
  name        = "koneksi-${local.env}-codebuild-logs-policy"
  description = "Allow CodeBuild to write logs to CloudWatch"
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
        Resource = [
          "arn:aws:logs:ap-southeast-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/koneksi-${local.env}-backend-build*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codebuild_logs_policy_attach" {
  name       = "koneksi-${local.env}-codebuild-logs-policy-attach"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = aws_iam_policy.codebuild_logs_policy.arn
}

resource "aws_iam_policy" "codebuild_s3_policy" {
  name        = "koneksi-${local.env}-codebuild-s3-policy"
  description = "Allow CodeBuild to read and write artifacts from the pipeline S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::koneksi-${local.env}-codepipeline-artifacts",
          "arn:aws:s3:::koneksi-${local.env}-codepipeline-artifacts/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codebuild_s3_policy_attach" {
  name       = "koneksi-${local.env}-codebuild-s3-policy-attach"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = aws_iam_policy.codebuild_s3_policy.arn
} 