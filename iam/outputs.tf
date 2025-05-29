output "user_access_keys" {
  description = "Map of usernames to their access keys"
  value = {
    for username, user in aws_iam_access_key.user_keys : username => {
      access_key_id     = user.id
      secret_access_key = user.secret
    }
  }
  sensitive = true
}

output "user_arns" {
  description = "Map of usernames to their ARNs"
  value = {
    for username, user in aws_iam_user.users : username => user.arn
  }
}

output "group_arns" {
  description = "Map of group names to their ARNs"
  value = {
    developers = aws_iam_group.developers.arn
    devops     = aws_iam_group.devops.arn
  }
} 