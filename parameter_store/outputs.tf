output "environment" {
  description = "Current environment"
  value       = local.environment
}

output "parameter_arns" {
  description = "ARNs of all standard parameters"
  value       = { for k, v in aws_ssm_parameter.parameters : k => v.arn }
}

output "secure_parameter_arns" {
  description = "ARNs of all secure parameters"
  value       = { for k, v in aws_ssm_parameter.secure_parameters : k => v.arn }
  sensitive   = true
}

output "parameter_names" {
  description = "Names of all standard parameters"
  value       = { for k, v in aws_ssm_parameter.parameters : k => v.name }
}

output "secure_parameter_names" {
  description = "Names of all secure parameters"
  value       = { for k, v in aws_ssm_parameter.secure_parameters : k => v.name }
  sensitive   = true
} 