terraform {
  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    key            = "discord_notifications/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "bongaquino-terraform-locks"
  }
} 