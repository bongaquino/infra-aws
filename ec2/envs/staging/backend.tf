terraform {
  backend "s3" {
    bucket = "koneksi-terraform-state-uniqueid"
    key    = "koneksi/ec2/staging/terraform.tfstate"
    region = "ap-southeast-1"
  }
} 