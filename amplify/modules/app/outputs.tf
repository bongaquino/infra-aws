output "app_id" {
  description = "ID of the created Amplify app"
  value       = aws_amplify_app.this.id
}

output "app_arn" {
  description = "ARN of the created Amplify app"
  value       = aws_amplify_app.this.arn
}

output "branch_name" {
  description = "Name of the created branch"
  value       = aws_amplify_branch.staging.branch_name
}

output "default_domain" {
  description = "Default domain of the app"
  value       = aws_amplify_app.this.default_domain
} 