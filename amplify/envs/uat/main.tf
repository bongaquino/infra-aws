provider "aws" {
  region  = "ap-southeast-1"
  profile = "bongaquino"
}

module "amplify" {
  source = "../../"

  # Basic Configuration
  environment   = var.environment
  project       = var.project
  name_prefix   = "${var.project}-${var.environment}"
  
  # App Configuration
  app_name      = "bongaquino-web-uat"
  repository    = "https://github.com/bongaquino/bongaquino-web"
  branch_name   = "main"
  
  # Domain Configuration
  domain_name   = "app-uat.example.com"
  
  # API Configuration
  api_url       = "https://uat.example.com"
  
  # Authentication (GitHub token for deployments)
  github_token  = var.github_token
  
  # Tags
  tags = var.tags
} 