output "iam_user_names" {
  description = "List of IAM user names created."
  value       = [for u in aws_iam_user.users : u.name]
}

output "iam_user_access_keys" {
  description = "Access keys for IAM users. Sensitive!"
  value       = { for k, v in aws_iam_access_key.user_keys : k => {
    id     = v.id
    secret = v.secret
  } }
  sensitive = true
}

output "iam_user_console_passwords" {
  description = "Console passwords for IAM users - managed externally"
  value       = "Passwords managed outside Terraform"
}

output "iam_group_names" {
  description = "List of IAM group names created."
  value       = [aws_iam_group.developers.name, aws_iam_group.operations.name, aws_iam_group.management.name]
} 