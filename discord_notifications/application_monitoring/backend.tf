terraform {
  backend "s3" {
    bucket = "koneksi-terraform-state"
    key    = "discord-notifications/application-monitoring/terraform.tfstate"
    region = "ap-southeast-1"
  }
} 