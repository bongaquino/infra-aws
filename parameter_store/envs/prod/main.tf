provider "aws" {
  region = "ap-southeast-1"
}

module "parameter_store" {
  source = "../.."
  
  environment = var.environment
  project     = var.project
  parameters  = var.parameters
  secrets     = var.secrets
  parameter_validation_rules = var.parameter_validation_rules
} 