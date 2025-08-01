terraform {
  backend "s3" {
    bucket         = "koneksi-terraform-state"
    key            = "discord_notifications/staging/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "koneksi-terraform-locks"
  }
} 