# =============================================================================
# Amplify App Configuration
# =============================================================================

# Create Amplify App
resource "aws_amplify_app" "this" {
  name                     = var.app_name
  repository               = replace(var.repository_url, "git@github.com:", "https://github.com/")
  access_token             = var.github_token
  platform                 = "WEB"
  enable_branch_auto_build = var.enable_auto_build
  enable_branch_auto_deletion = var.enable_branch_auto_deletion

  # Build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - git checkout staging
            - npm install -g pnpm
            - pnpm install
        build:
          commands:
            - pnpm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
          - .pnpm-store/**/*
  EOT

  # Environment variables
  environment_variables = merge(
    {
      NODE_ENV = var.environment
      VITE_ENVIRONMENT = var.environment
    },
    var.environment_variables
  )

  tags = merge(
    var.tags,
    {
      Name      = var.app_name
      Component = "amplify"
      Role      = "web-app"
    }
  )
}

# Create branch for staging
resource "aws_amplify_branch" "staging" {
  app_id      = aws_amplify_app.this.id
  branch_name = "staging"
  
  # Enable auto build and deploy
  enable_auto_build = var.enable_auto_build
  
  # Environment variables specific to staging
  environment_variables = merge(
    {
      NODE_ENV = var.environment
      VITE_ENVIRONMENT = var.environment
    },
    var.environment_variables
  )

  # Framework
  framework = "React"
}

# Trigger initial build
resource "null_resource" "trigger_build" {
  depends_on = [aws_amplify_branch.staging]

  provisioner "local-exec" {
    command = <<-EOT
      aws amplify start-job \
        --app-id ${aws_amplify_app.this.id} \
        --branch-name staging \
        --job-type RELEASE
    EOT
  }
} 