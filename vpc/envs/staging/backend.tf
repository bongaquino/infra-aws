terraform {
  backend "s3" {
    bucket = "koneksi-terraform-state-uniqueid"
    key    = "koneksi/vpc/staging/terraform.tfstate"
    region = "ap-southeast-1"
  }
} 