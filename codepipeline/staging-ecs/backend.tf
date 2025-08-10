terraform {
  backend "s3" {
    bucket         = "bongaquino-terraform-state"
    key            = "codepipeline/staging-ecs/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "bongaquino-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
} 