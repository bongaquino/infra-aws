module "vpc" {
  source = "../../../vpc"

  environment         = var.environment
  project            = var.project
  name_prefix        = "${var.project}-${var.environment}"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  vpc_cidr           = "10.2.0.0/16"
  public_subnets     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnets    = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
  database_subnets   = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]
  elasticache_subnets = ["10.2.31.0/24", "10.2.32.0/24", "10.2.33.0/24"]
}

module "alb" {
  source = "../../"

  region              = var.region
  environment         = var.environment
  project            = var.project
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = var.certificate_arn
  target_port        = var.target_port
  sns_topic_arn      = var.sns_topic_arn
  alb_security_group_id = module.vpc.alb_security_group_id
} 