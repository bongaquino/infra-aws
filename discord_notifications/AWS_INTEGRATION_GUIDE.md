# 🚨 Complete AWS Monitoring with Discord Integration Guide

## 📋 Overview

This guide covers deploying comprehensive AWS monitoring that sends alerts to Discord for:

- **🔧 Infrastructure**: ALB, ECS, CloudWatch alarms
- **🚀 CI/CD**: CodePipeline, CodeBuild, ECR scans  
- **🔒 Security**: CloudTrail, GuardDuty, Config compliance
- **💰 Cost**: Budget alerts, anomaly detection, optimization
- **📊 Performance**: Application logs, error detection

## 🎯 Quick Start - Deploy Everything

### 1. Deploy ALB Integration
```bash
cd koneksi-aws/alb/envs/uat
terraform apply
```

### 2. Deploy ECS Monitoring
```bash
cd koneksi-aws/ecs/envs/uat
terraform apply
```

### 3. Deploy CodePipeline Monitoring
```bash
cd koneksi-aws/codepipeline/uat
terraform apply
```

### 4. Deploy Security Monitoring
```bash
cd koneksi-aws/cloudtrail
terraform apply
```

### 5. Deploy Cost Monitoring
```bash
cd koneksi-aws/cost_monitoring
terraform apply
```

## 📱 What You'll See in Discord

### 🔧 Infrastructure Alerts
```
🚨 ALB Error Rate High
━━━━━━━━━━━━━━━━━━━━━━
ALB koneksi-uat-alb is experiencing high 5xx error rate

Environment: UAT
Error Rate: 15.3%
Threshold: 10%
Time: 2024-01-15 10:30:00 UTC

🔗 View ALB Dashboard
```

### 🐳 ECS Service Alerts
```
⚠️ ECS High CPU Usage
━━━━━━━━━━━━━━━━━━━━━━
ECS service koneksi-uat-service CPU usage is high

Cluster: koneksi-uat-cluster
Current CPU: 85%
Threshold: 80%
Auto-scaling: Active

📊 View ECS Metrics
```

### 🚀 Deployment Notifications
```
🚀 Deployment Started
━━━━━━━━━━━━━━━━━━━━━━
Pipeline koneksi-uat-backend-pipeline has STARTED

Execution ID: abc123-def456
Stage: Source
Commit: feat/new-feature
Author: @developer

⏳ Estimated completion: 15 minutes
```

### 🔒 Security Alerts
```
🚨 CRITICAL Security Alert
━━━━━━━━━━━━━━━━━━━━━━
Root user activity detected

Event: ConsoleLogin
Source IP: 203.0.113.5  
Region: ap-southeast-1
Time: 2024-01-15 10:30:00 UTC

⚠️ IMMEDIATE ACTION REQUIRED
```

### 💰 Cost Alerts
```
💸 Budget Alert
━━━━━━━━━━━━━━━━━━━━━━
Monthly budget 80% exceeded

Budget: $500/month
Current: $401.50
Forecast: $510 (102%)

Top Services:
• ECS: $180
• ALB: $95
• S3: $75

📊 View Cost Dashboard
```

## ⚙️ Configuration Examples

### Manual Test Messages

Send a test alert:
```bash
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-1:985869370256:koneksi-uat-uat-discord-notifications" \
  --message '{
    "title": "Test Alert",
    "description": "Testing Discord integration",
    "type": "info",
    "details": {
      "Service": "Manual Test",
      "Environment": "UAT",
      "Status": "Success"
    }
  }' \
  --subject "Manual Test"
```

### Custom Application Alerts

From your application code:
```python
import boto3
import json

sns = boto3.client('sns')
topic_arn = 'arn:aws:sns:ap-southeast-1:985869370256:koneksi-uat-uat-discord-notifications'

def send_discord_alert(title, description, alert_type="warning", details=None):
    message = {
        "title": title,
        "description": description,
        "type": alert_type,
        "details": details or {}
    }
    
    sns.publish(
        TopicArn=topic_arn,
        Message=json.dumps(message),
        Subject=title
    )

# Usage examples
send_discord_alert(
    title="🔥 High Error Rate",
    description="API error rate above threshold",
    alert_type="error",
    details={
        "Error Rate": "15.2%",
        "Endpoint": "/api/v1/upload", 
        "Time": "2024-01-15 10:30:00 UTC"
    }
)
```

### CloudWatch Custom Metrics

Create custom metrics that trigger Discord alerts:
```bash
aws cloudwatch put-metric-data \
  --namespace "Koneksi/Application" \
  --metric-data MetricName=UploadErrors,Value=10,Unit=Count
```

## 🔧 Advanced Configuration

### Environment-Specific Channels

Update webhook URLs for different environments:
```bash
# Update UAT webhook
terraform apply -var="discord_webhook_url=https://discord.com/api/webhooks/uat-webhook"

# Update Production webhook  
terraform apply -var="discord_webhook_url=https://discord.com/api/webhooks/prod-webhook"
```

### Filter Alerts by Severity

Modify the Discord Lambda to filter by severity:
```python
def should_send_alert(alert_type, severity=None):
    # Only send high/critical alerts to Discord
    if severity and severity.lower() in ['high', 'critical']:
        return True
    
    # Send all deployment notifications
    if alert_type in ['deployment', 'build']:
        return True
        
    return False
```

### Custom Embed Colors

Customize Discord embed colors in `discord_notifier.py`:
```python
COLORS = {
    'success': 0x00ff00,  # Green
    'warning': 0xffaa00,  # Orange  
    'error': 0xff0000,    # Red
    'info': 0x0099ff,     # Blue
    'deployment': 0x9900ff, # Purple
    'security': 0xff3300   # Dark Red
}
```

## 📊 Monitoring Dashboard URLs

Access your monitoring dashboards:

- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1
- **ECS**: https://console.aws.amazon.com/ecs/home?region=ap-southeast-1#/clusters
- **CodePipeline**: https://console.aws.amazon.com/codesuite/codepipeline/pipelines
- **Cost Explorer**: https://console.aws.amazon.com/cost-management/home
- **CloudTrail**: https://console.aws.amazon.com/cloudtrail/home?region=ap-southeast-1

## 🚨 Alert Priority Levels

| Priority | Discord Color | Use Cases |
|----------|---------------|-----------|
| 🚨 CRITICAL | Red | Root user activity, security breaches, service outages |
| ⚠️ HIGH | Orange | High error rates, failed deployments, resource exhaustion |
| 💡 MEDIUM | Yellow | Policy changes, cost thresholds, performance degradation |
| ℹ️ LOW | Blue | Successful deployments, routine maintenance, informational |

## 🔧 Troubleshooting

### Discord Messages Not Appearing

1. **Check Lambda logs**:
   ```bash
   aws logs tail /aws/lambda/koneksi-uat-uat-discord-notifier --follow
   ```

2. **Test webhook manually**:
   ```bash
   curl -X POST "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "Test message"}'
   ```

3. **Verify SNS permissions**:
   ```bash
   aws sns get-topic-attributes --topic-arn "YOUR_SNS_TOPIC_ARN"
   ```

### Missing Alerts

1. **Check CloudWatch alarm states**:
   ```bash
   aws cloudwatch describe-alarms --state-value ALARM
   ```

2. **Review metric filters**:
   ```bash
   aws logs describe-metric-filters --log-group-name "/aws/cloudtrail/koneksi-uat"
   ```

3. **Test EventBridge rules**:
   ```bash
   aws events list-rules --name-prefix "koneksi-uat"
   ```

## 🎛️ Cost Optimization

Monitor your alerting costs:

- **SNS**: ~$0.50 per 1M messages
- **Lambda**: ~$0.20 per 1M requests  
- **CloudWatch**: ~$0.30 per alarm per month
- **EventBridge**: ~$1.00 per 1M events

**Estimated monthly cost**: $10-30 for comprehensive monitoring

## 🔄 Regular Maintenance

### Weekly Tasks
- [ ] Review Discord channel for alert volume
- [ ] Check false positive rate
- [ ] Update alert thresholds if needed

### Monthly Tasks  
- [ ] Review cost anomaly patterns
- [ ] Update budget thresholds
- [ ] Audit security alert effectiveness
- [ ] Clean up unused alarms

### Quarterly Tasks
- [ ] Audit all monitoring rules
- [ ] Review and update escalation procedures
- [ ] Test disaster recovery procedures
- [ ] Update documentation

## 📞 Getting Help

If you encounter issues:

1. **Check the logs**: All services log to CloudWatch
2. **Test components**: Use the manual test examples above
3. **Review permissions**: Ensure IAM roles have proper access
4. **Discord limits**: Rate limits are 50 messages per 10 seconds

## 🚀 Next Steps

1. **Custom Dashboards**: Build Grafana/CloudWatch dashboards
2. **Automated Remediation**: Add Lambda functions to auto-fix common issues
3. **Machine Learning**: Use CloudWatch Anomaly Detection for advanced alerting
4. **Multi-Environment**: Extend to staging and production environments

---

🎉 **Congratulations!** You now have comprehensive AWS monitoring with Discord notifications. Your infrastructure is being watched 24/7! 🎉 