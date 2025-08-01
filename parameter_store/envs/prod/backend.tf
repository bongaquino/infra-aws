terraform {
  backend "s3" {
    bucket         = "koneksi-terraform-state"
    key            = "parameter_store/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "koneksi-terraform-locks"
    encrypt        = true
  }
} 