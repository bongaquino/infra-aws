terraform {
  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    key            = "s3/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "bongaquino-terraform-locks"
  }
}
