terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "koneksi/vpc/prod/terraform.tfstate"
    region = "ap-southeast-1"
  }
} 