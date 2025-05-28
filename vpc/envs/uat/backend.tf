terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "koneksi/vpc/uat/terraform.tfstate"
    region = "ap-southeast-1"
  }
} 