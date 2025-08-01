terraform {
  backend "s3" {
    bucket         = "koneksi-terraform-state"
    key            = "parameter_store/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
} 