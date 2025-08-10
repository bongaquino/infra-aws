# Using custom Lambda setup instead of module for clean naming
# module "discord_notifications" {
#   source = "../../"
#
#   # Required variables
#   discord_webhook_url = var.discord_webhook_url
#   environment        = var.environment
#   project           = var.project
#
#   # Optional customization
#   name_prefix                         = "bongaquino-uat"
#   discord_username                    = var.discord_username
#   discord_avatar_url                  = var.discord_avatar_url
#   log_retention_days                  = var.log_retention_days
#   store_webhook_in_parameter_store    = var.store_webhook_in_parameter_store
#   enable_lambda_monitoring            = var.enable_lambda_monitoring
#   
#   # Message formatting
#   message_color           = var.message_color
#   critical_message_color  = var.critical_message_color
#   warning_message_color   = var.warning_message_color
#   success_message_color   = var.success_message_color
#   enable_mentions         = var.enable_mentions
#
#   # Alarm actions (SNS topics to notify if Lambda fails)
#   alarm_actions = var.alarm_actions
#
#   tags = var.tags
# } 