terraform {
  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "bongaquino-terraform-locks"
  }
} 