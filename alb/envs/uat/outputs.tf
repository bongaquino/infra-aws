# Main ALB Outputs
output "main_alb_dns_name" {
  description = "The DNS name of the main ALB"
  value       = module.main_alb.alb_dns_name
}

output "main_alb_arn" {
  description = "The ARN of the main ALB"
  value       = module.main_alb.alb_arn
}

output "main_target_group_arn" {
  description = "The ARN of the main target group"
  value       = module.main_alb.target_group_arn
}

# Services ALB Outputs
output "services_alb_dns_name" {
  description = "The DNS name of the services ALB"
  value       = module.services_alb.services_alb_dns_name
}

output "services_alb_arn" {
  description = "The ARN of the services ALB"
  value       = module.services_alb.services_alb_arn
}

output "services_target_group_arn" {
  description = "The ARN of the services target group"
  value       = module.services_alb.services_target_group_arn
}

output "services_listener_arn" {
  description = "The ARN of the services ALB listener"
  value       = module.services_alb.services_listener_arn
}

# Common Outputs
output "security_group_id" {
  description = "The ID of the security group used by the ALB"
  value       = var.alb_security_group_id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for CloudWatch alarms"
  value       = module.main_alb.sns_topic_arn
} 