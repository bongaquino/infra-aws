terraform {
  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    key            = "alb/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "bongaquino-terraform-locks"
    encrypt        = true
  }
} 