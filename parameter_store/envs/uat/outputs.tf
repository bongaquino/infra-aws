output "parameter_arns" {
  description = "ARNs of created SSM parameters"
  value       = module.parameter_store.parameter_arns
}

output "secret_arns" {
  description = "ARNs of created secrets"
  value       = module.parameter_store.secret_arns
} 