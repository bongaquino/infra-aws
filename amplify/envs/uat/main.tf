provider "aws" {
  region  = "ap-southeast-1"
  profile = "koneksi"
}

module "amplify" {
  source = "../../"

  # Basic Configuration
  environment   = var.environment
  project       = var.project
  name_prefix   = "${var.project}-${var.environment}"
  
  # App Configuration
  app_name      = "koneksi-web-uat"
  repository    = "https://github.com/koneksi-tech/koneksi-web"
  branch_name   = "main"
  
  # Domain Configuration
  domain_name   = "app-uat.koneksi.co.kr"
  
  # API Configuration
  api_url       = "https://uat.koneksi.co.kr"
  
  # Authentication (GitHub token for deployments)
  github_token  = var.github_token
  
  # Tags
  tags = var.tags
} 