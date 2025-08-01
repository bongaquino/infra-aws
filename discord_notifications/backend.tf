terraform {
  backend "s3" {
    bucket               = "koneksi-terraform-state"
    key                  = "discord_notifications/health_monitoring/terraform.tfstate"
    region               = "ap-southeast-1"
    encrypt              = true
    dynamodb_table       = "koneksi-terraform-locks"
    shared_credentials_file = "~/.aws/credentials"
    profile              = "koneksi"
  }
} 