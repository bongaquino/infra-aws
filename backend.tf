terraform {
  backend "s3" {
    # These values will be overridden by -backend-config
    bucket         = "placeholder"
    key            = "placeholder"
    region         = "placeholder"
    encrypt        = true
    dynamodb_table = "placeholder"
  }
} 