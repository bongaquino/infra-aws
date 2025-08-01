provider "aws" {
  region  = "ap-southeast-1"
  profile = "koneksi"
}

module "amplify" {
  source = "../../"

  # Basic Configuration
  environment     = var.environment
  project         = var.project
  name_prefix     = "${var.project}-${var.environment}"
  
  # App Configuration
  app_name        = var.app_name
  repository      = var.repository
  branch_name     = var.branch_name
  branch_stage    = var.branch_stage
  vite_environment = var.vite_environment
  
  # Domain Configuration (optional)
  domain_name     = var.domain_name
  
  # Authentication (GitHub token for deployments)
  github_token    = var.github_token
  
  # Tags
  tags = var.tags
} 