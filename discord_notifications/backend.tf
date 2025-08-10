terraform {
  backend "s3" {
    bucket               = "bongaquino-terraform-state"
    key                  = "discord_notifications/health_monitoring/terraform.tfstate"
    region               = "ap-southeast-1"
    encrypt              = true
    dynamodb_table       = "bongaquino-terraform-locks"
    shared_credentials_file = "~/.aws/credentials"
<<<<<<< HEAD
    profile              = "bongaquino"
=======
    profile              = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  }
} 