output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs.task_definition_arn
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = module.ecs.task_execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = module.ecs.task_role_arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs.log_group_name
} 