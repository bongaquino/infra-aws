terraform {
  backend "s3" {
    bucket = "bongaquino-terraform-state"
    key    = "discord-notifications/application-monitoring/terraform.tfstate"
    region = "ap-southeast-1"
  }
} 