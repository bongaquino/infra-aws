output "app_id" {
  description = "ID of the created Amplify app"
  value       = module.amplify.app_id
}

output "app_arn" {
  description = "ARN of the created Amplify app"
  value       = module.amplify.app_arn
}

output "branch_name" {
  description = "Name of the created branch"
  value       = module.amplify.branch_name
}

output "default_domain" {
  description = "Default domain of the app"
  value       = module.amplify.default_domain
} 