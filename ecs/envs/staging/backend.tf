terraform {
  backend "s3" {
    bucket         = "koneksi-terraform-state"
    key            = "ecs/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "koneksi-terraform-locks"
    encrypt        = true
  }
} 