# NEW ECS CodePipeline for bongaquino-backend to ECS (bongaquino-staging-backend-pipeline)

provider "aws" {
  region = "ap-southeast-1"
}

locals {
  env = "staging"
  github_repo = "bongaquino-tech/bongaquino-backend"  
  github_branch = "staging"
}

# ECR Repository for ECS deployment
resource "aws_ecr_repository" "backend_ecs" {
  name = "bongaquino-${local.env}-backend-ecs"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project     = "bongaquino"
    Environment = local.env
    Service     = "ecs"
    ManagedBy   = "terraform"
  }
}

# S3 bucket for CodePipeline artifacts (ECS)
resource "aws_s3_bucket" "codepipeline_artifacts_ecs" {
  bucket = "bongaquino-${local.env}-ecs-cd-artifacts"
  force_destroy = true
  tags = {
    Project     = "bongaquino"
    Environment = local.env
    Service     = "ecs"
    ManagedBy   = "terraform"
  }
}

# IAM Role for CodePipeline (ECS)
resource "aws_iam_role" "codepipeline_role_ecs" {
  name = "bongaquino-${local.env}-ecs-cd-pipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_ecs" {
  role       = aws_iam_role.codepipeline_role_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# Custom policy for CodeStar connections (ECS)
resource "aws_iam_policy" "codepipeline_codestar_policy_ecs" {
  name        = "bongaquino-${local.env}-ecs-cd-pipeline-codestar-policy"
  description = "Allow CodePipeline to use CodeStar connections for ECS"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = aws_codestarconnections_connection.github_ecs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codestar_policy_attach_ecs" {
  role       = aws_iam_role.codepipeline_role_ecs.name
  policy_arn = aws_iam_policy.codepipeline_codestar_policy_ecs.arn
}

# Custom policy for CodeBuild access (ECS)
resource "aws_iam_policy" "codepipeline_codebuild_policy_ecs" {
  name        = "bongaquino-${local.env}-ecs-cd-pipeline-codebuild-policy"
  description = "Allow CodePipeline to start CodeBuild projects for ECS"
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
        Resource = aws_codebuild_project.staging_build_ecs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_policy_attach_ecs" {
  role       = aws_iam_role.codepipeline_role_ecs.name
  policy_arn = aws_iam_policy.codepipeline_codebuild_policy_ecs.arn
}

# ECS deployment policy for CodePipeline
resource "aws_iam_policy" "codepipeline_ecs_policy" {
  name        = "bongaquino-${local.env}-ecs-cd-pipeline-ecs-policy"
  description = "Allow CodePipeline to deploy to ECS"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "application-autoscaling:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_ecs_policy_attach" {
  role       = aws_iam_role.codepipeline_role_ecs.name
  policy_arn = aws_iam_policy.codepipeline_ecs_policy.arn
}

# IAM Role for CodeBuild (ECS)
resource "aws_iam_role" "codebuild_role_ecs" {
  name = "bongaquino-${local.env}-ecs-cd-build-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_ecs" {
  role       = aws_iam_role.codebuild_role_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

# ECR policy for CodeBuild to push images (ECS)
resource "aws_iam_policy" "codebuild_ecr_policy_ecs" {
  name        = "bongaquino-${local.env}-ecs-cd-build-ecr-policy"
  description = "Allow CodeBuild to push to ECR for ECS deployment"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer", 
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
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

resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy_attach_ecs" {
  role       = aws_iam_role.codebuild_role_ecs.name
  policy_arn = aws_iam_policy.codebuild_ecr_policy_ecs.arn
}

# CodeBuild project for ECS container build  
resource "aws_codebuild_project" "staging_build_ecs" {
  name          = "bongaquino-${local.env}-ecs-build"
  description   = "Build bongaquino-backend container for staging ECS"
  service_role  = aws_iam_role.codebuild_role_ecs.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-southeast-1"
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "985869370256"
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
    Service     = "ecs"
    ManagedBy   = "terraform"
  }
}

# CodePipeline for staging ECS deployment
resource "aws_codepipeline" "staging_backend_pipeline" {
  name     = "bongaquino-${local.env}-backend-pipeline"
  role_arn = aws_iam_role.codepipeline_role_ecs.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts_ecs.bucket
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
        ConnectionArn     = aws_codestarconnections_connection.github_ecs.arn
        FullRepositoryId  = local.github_repo
        BranchName        = local.github_branch
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
        ProjectName = aws_codebuild_project.staging_build_ecs.name
      }
      version = "1"
    }
  }
  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        ClusterName = "bongaquino-staging-cluster"
        ServiceName = "bongaquino-staging-service"
        FileName    = "imagedefinitions.json"
      }
      version = "1"
    }
  }
}

# GitHub connection for ECS
resource "aws_codestarconnections_connection" "github_ecs" {
  name          = "bongaquino-staging-github-ecs"
  provider_type = "GitHub"
}

# IAM policies for S3 access (ECS)
resource "aws_iam_policy" "codepipeline_s3_policy_ecs" {
  name        = "bongaquino-${local.env}-ecs-cd-pipeline-s3-policy"
  description = "Allow CodePipeline to access its artifact bucket for ECS"
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
          aws_s3_bucket.codepipeline_artifacts_ecs.arn,
          "${aws_s3_bucket.codepipeline_artifacts_ecs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_policy_attach_ecs" {
  role       = aws_iam_role.codepipeline_role_ecs.name
  policy_arn = aws_iam_policy.codepipeline_s3_policy_ecs.arn
}

# CloudWatch Logs policy for CodeBuild (ECS)
resource "aws_iam_policy" "codebuild_logs_policy_ecs" {
  name        = "bongaquino-${local.env}-ecs-cd-build-logs-policy"
  description = "Allow CodeBuild to write to CloudWatch Logs for ECS"
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

resource "aws_iam_role_policy_attachment" "codebuild_logs_policy_attach_ecs" {
  role       = aws_iam_role.codebuild_role_ecs.name
  policy_arn = aws_iam_policy.codebuild_logs_policy_ecs.arn
}

# S3 policy for CodeBuild (ECS)
resource "aws_iam_policy" "codebuild_s3_policy_ecs" {
  name        = "bongaquino-${local.env}-ecs-cd-build-s3-policy"
  description = "Allow CodeBuild to access S3 artifacts for ECS"
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
          aws_s3_bucket.codepipeline_artifacts_ecs.arn,
          "${aws_s3_bucket.codepipeline_artifacts_ecs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_policy_attach_ecs" {
  role       = aws_iam_role.codebuild_role_ecs.name
  policy_arn = aws_iam_policy.codebuild_s3_policy_ecs.arn
}

# Outputs
output "ecs_pipeline_arn" {
  description = "ARN of the staging ECS deployment pipeline"
  value       = aws_codepipeline.staging_backend_pipeline.arn
}

output "ecs_github_connection_arn" {
  description = "ARN of the GitHub connection for ECS"
  value       = aws_codestarconnections_connection.github_ecs.arn
}

output "ecs_github_connection_status" {
  description = "Status of the GitHub connection for ECS"
  value       = aws_codestarconnections_connection.github_ecs.connection_status
}

output "ecs_ecr_repository_url" {
  description = "URL of the ECR repository for ECS"
  value       = aws_ecr_repository.backend_ecs.repository_url
} 