terraform {
  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    key            = "parameter_store/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "bongaquino-terraform-locks"
    encrypt        = true
    workspace_key_prefix = "parameter_store"
  }
} 