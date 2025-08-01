terraform {
  backend "s3" {
    bucket         = "koneksi-terraform-state"
    key            = "ec2/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "koneksi-terraform-locks"
  }
}
