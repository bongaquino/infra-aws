output "parameter_arns" {
  description = "ARNs of created SSM parameters"
  value       = module.parameter_store.parameter_arns
}

output "secure_parameter_arns" {
  description = "ARNs of created secure parameters"
  value       = module.parameter_store.secure_parameter_arns
  sensitive   = true
} 