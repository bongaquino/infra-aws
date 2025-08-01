provider "aws" {
  region = "ap-southeast-1"
}

module "parameter_store" {
  source = "../.."
  
  environment = var.environment
  parameters  = var.parameters
  secure_parameters = var.secure_parameters
} 