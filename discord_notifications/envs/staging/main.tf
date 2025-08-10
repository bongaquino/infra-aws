# =============================================================================
# Discord Notifications for Staging Environment
# =============================================================================

# DEPRECATED: Using lambda_only.tf approach for consistency with UAT
# This module approach is commented out in favor of direct resource management

# module "discord_notifications" {
#   source = "../../"
#
#   # Environment Configuration
#   environment = "staging"
#   project     = "bongaquino"
#
#   # Discord Configuration (Same webhook as UAT, different bot name)
#   discord_webhook_url = "https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
#   discord_username    = "🟡 bongaquino Staging Bot"
#   discord_avatar_url  = "https://example.com/staging-bot-avatar.png"
#
#   # Message Configuration
#   success_message_color = "65280"     # Green (0x00ff00 = 65280)
#   warning_message_color = "16776960"  # Orange (0xffaa00 = 16755360)
#   critical_message_color = "15158332" # Red (0xe74c3c = 15158332) - Fix failed deployments!
#   message_color         = "3394815"   # Light Blue (0x3399ff = 3394815)
#
#   # Advanced Configuration
#   enable_lambda_monitoring        = true
#   store_webhook_in_parameter_store = true
#   log_retention_days             = 30
#   
#   # Tags
#   tags = {
#     Environment = "staging"
#     Project     = "bongaquino"
#     Purpose     = "discord-notifications"
#     ManagedBy   = "terraform"
#     CostCenter  = "engineering"
#   }
# }

# =============================================================================
# NOTE: Now using lambda_only.tf for direct resource management
# This approach provides better consistency with UAT environment setup
# ============================================================================= 