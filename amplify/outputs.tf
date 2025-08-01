# =============================================================================
# Amplify App Outputs
# =============================================================================
output "amplify_app_id" {
  description = "The ID of the Amplify app"
  value       = aws_amplify_app.main.id
}

output "amplify_app_arn" {
  description = "The ARN of the Amplify app"
  value       = aws_amplify_app.main.arn
}

output "amplify_app_name" {
  description = "The name of the Amplify app"
  value       = aws_amplify_app.main.name
}

output "amplify_app_default_domain" {
  description = "The default domain for the Amplify app"
  value       = aws_amplify_app.main.default_domain
}

# =============================================================================
# Amplify Branch Outputs
# =============================================================================
output "amplify_branch_name" {
  description = "The name of the Amplify branch"
  value       = aws_amplify_branch.main.branch_name
}

output "amplify_branch_arn" {
  description = "The ARN of the Amplify branch"
  value       = aws_amplify_branch.main.arn
}

# =============================================================================
# Amplify Domain Outputs (if configured)
# =============================================================================
output "amplify_domain_name" {
  description = "The domain name associated with the Amplify app"
  value       = var.domain_name != "" ? aws_amplify_domain_association.main[0].domain_name : null
}

output "amplify_domain_status" {
  description = "The status of the domain association"
  value       = var.domain_name != "" ? aws_amplify_domain_association.main[0].certificate_verification_dns_record : null
}

# =============================================================================
# Amplify Webhook Outputs (Commented out - no webhook in staging)
# =============================================================================
# output "amplify_webhook_arn" {
#   description = "The ARN of the Amplify webhook"
#   value       = aws_amplify_webhook.main.arn
# }

# output "amplify_webhook_url" {
#   description = "The URL of the Amplify webhook"
#   value       = aws_amplify_webhook.main.url
# }

# =============================================================================
# Application URLs
# =============================================================================
output "application_url" {
  description = "The URL where the application is deployed"
  value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.main.default_domain}"
}

output "amplify_console_url" {
  description = "URL to the Amplify console for this app"
  value       = "https://console.aws.amazon.com/amplify/apps/${aws_amplify_app.main.id}/branches/${aws_amplify_branch.main.branch_name}"
} 