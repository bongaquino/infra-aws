# 🚀 Koneksi AWS Discord Monitoring System

Complete monitoring solution with Discord notifications for the Koneksi platform.

## 🎯 **Quick Start**

1. **Deploy UAT (Already Configured):**
   ```bash
   ./deploy_all_environments.sh
   # Choose option 1: Deploy UAT only
   ```

2. **Deploy All Environments:**
   ```bash
   ./deploy_all_environments.sh
   # Choose option 4: Deploy All Environments
   ```

## 📋 **What You Get**

### 🔔 **Discord Notifications**
- Real-time alerts in Discord channels
- Color-coded severity levels
- Rich embeds with detailed information
- Environment-specific channels

### 📊 **Comprehensive Monitoring**
- **Infrastructure**: ALB, ECS, EC2, RDS
- **Applications**: API performance, errors, metrics
- **Security**: IAM, GuardDuty, failed logins
- **CI/CD**: Pipeline status, deployments
- **Costs**: Budget alerts, anomaly detection
- **Business**: User metrics, growth tracking

### 🌍 **Multi-Environment Support**
- **UAT**: `#koneksi-alerts` (active ✅)
- **Staging**: `#koneksi-alerts` (same channel, ready to deploy 🔄)

---

## 🛠️ **Architecture Overview**

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   AWS Services  │───▶│ CloudWatch   │───▶│ SNS Topic       │
│   (ALB, ECS,    │    │ Alarms       │    │                 │
│    RDS, etc.)   │    │              │    │                 │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                      │
                                                      ▼
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│ Discord Channel │◀───│ Lambda       │◀───│ SNS Message     │
│ #koneksi-alerts │    │ Function     │    │                 │
│                 │    │              │    │                 │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

---

## 🔧 **Setup Instructions**

### 1. **Discord Webhook Setup**

#### UAT (Already Done ✅)
- Channel: `#koneksi-alerts`
- Webhook: Already configured

#### Staging Setup (Next Step)
- **No setup needed!** Staging uses the same webhook as UAT
- Same Discord channel: `#koneksi-alerts`
- Different bot name: `🟡 Koneksi Staging Bot`
- Ready to deploy immediately

### 2. **Deploy Monitoring**

```bash
cd koneksi-aws/discord_notifications
./deploy_all_environments.sh
```

**Menu Options:**
- `1`: Deploy UAT only (webhook ready ✅)
- `2`: Deploy Staging only (same webhook as UAT ✅)
- `3`: Deploy both UAT & Staging
- `5`: Test existing environments  
- `6`: Show webhook instructions
- `7`: Create deployment summary

---

## 📱 **Go Backend Integration**

### 1. **Add Monitoring Package**

Copy `application_monitoring/go_integration.go` to your backend:

```bash
cp application_monitoring/go_integration.go ../koneksi-backend/monitoring/
```

### 2. **Add Dependencies**

```bash
cd ../koneksi-backend
go get github.com/aws/aws-sdk-go-v2/service/cloudwatch
go get github.com/aws/aws-sdk-go-v2/service/sns
```

### 3. **Initialize in Your App**

```go
// main.go or wherever you initialize your app
monitor, err := monitoring.NewDiscordMonitoring("uat", "koneksi-backend")
if err != nil {
    log.Fatal("Failed to initialize monitoring:", err)
}

// Make monitor available globally
// Add to your dependency injection container
```

### 4. **Add Monitoring to APIs**

```go
// Example: File upload endpoint
func (h *Handler) UploadFile(c *gin.Context) {
    start := time.Now()
    
    // Your upload logic here...
    success := true // or false based on result
    fileSize := int64(1024000) // actual file size
    
    // Record metrics
    responseTime := time.Since(start).Milliseconds()
    h.monitor.RecordAPIResponseTime(c.Request.Context(), "/api/v1/upload", float64(responseTime))
    h.monitor.RecordFileUploadSuccess(c.Request.Context(), success, fileSize)
    
    // Send critical alerts if needed
    if someErrorCondition {
        h.monitor.SendCriticalAlert(c.Request.Context(), 
            "File Upload Failed", 
            "Critical error during file upload",
            map[string]interface{}{
                "UserID": userID,
                "Error": err.Error(),
                "Timestamp": time.Now(),
            })
    }
}
```

---

## 🎨 **Alert Types & Colors**

| Type | Color | Use Case | Example |
|------|-------|----------|---------|
| 🚨 **CRITICAL** | Red (#FF0000) | System down, data loss | Database connection lost |
| ⚠️ **WARNING** | Orange (#FF9900) | Performance issues | High response times |
| ℹ️ **INFO** | Blue (#0099FF) | Deployments, updates | Pipeline completed |
| ✅ **SUCCESS** | Green (#00DD00) | Successful operations | Deployment success |

---

## 🔍 **Monitoring Coverage**

### **Infrastructure Alerts**
- ALB 5XX errors > 5%
- ECS task failures
- RDS connection issues
- High CPU/memory usage
- Disk space warnings

### **Application Alerts**
- API response time > 1s (UAT) / 500ms (prod)
- File upload failure rate > 5%
- Authentication failures > 20/5min
- Application panics/crashes
- Database slow queries

### **Security Alerts**
- Root account usage
- Failed login attempts
- IAM policy changes
- GuardDuty findings
- Security group modifications

### **Business Alerts**
- Daily active users drop
- Storage growth anomalies
- Revenue metric changes
- Conversion rate drops

### **Cost Alerts**
- Monthly budget exceeded
- Cost anomalies detected
- Expensive resource usage
- Unused resource detection

---

## 🧪 **Testing Your Setup**

### 1. **Test SNS Topic**
```bash
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-1:985869370256:koneksi-uat-uat-discord-notifications" \
  --message "Test message from command line" \
  --subject "Test Alert"
```

### 2. **Test CloudWatch Alarm**
```bash
aws cloudwatch set-alarm-state \
  --alarm-name "koneksi-uat-alb-5xx-error-rate" \
  --state-value ALARM \
  --state-reason "Testing alarm"
```

### 3. **Test from Go App**
```go
monitor.SendInfoAlert(ctx, "Test Alert", "Testing Discord integration", map[string]interface{}{
    "Environment": "uat",
    "TestTime": time.Now(),
})
```

---

## 📊 **Monitoring Dashboard**

Access your metrics:

1. **CloudWatch Console**
   - Custom namespace: `Koneksi/Application`
   - Business namespace: `Koneksi/Business`

2. **Key Metrics to Watch**
   - `ApiResponseTime`
   - `FileUploadSuccessRate`
   - `ActiveUsers`
   - `DatabaseConnectionPoolUtilization`
   - `MemoryUtilization`

---

## 🔧 **Customization**

### **Adjust Alert Thresholds**

Edit `application_monitoring/custom_metrics.tf`:

```hcl
# Change API response time threshold
threshold = var.api_response_time_threshold  # 500ms for prod, 1000ms for uat

# Change active users spike threshold
threshold = var.active_users_threshold  # 10000 for prod, 1000 for uat
```

### **Add Custom Metrics**

```go
// Record custom business metric
monitor.SendMetric(ctx, monitoring.MetricData{
    MetricName: "DailyActiveUsers",
    Value:      float64(userCount),
    Unit:       types.StandardUnitCount,
    Namespace:  "Koneksi/Business",
})
```

### **Create Custom Alerts**

```hcl
resource "aws_cloudwatch_metric_alarm" "custom_metric" {
  alarm_name          = "koneksi-${var.environment}-custom-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CustomMetric"
  namespace           = "Koneksi/Application"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Custom metric exceeded threshold"
  alarm_actions       = [data.aws_sns_topic.discord_notifications.arn]
}
```

---

## 🐛 **Troubleshooting**

### **Lambda Function Issues**
```bash
# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/koneksi"
aws logs tail "/aws/lambda/koneksi-uat-uat-discord-notifier" --follow
```

### **SNS Topic Issues**
```bash
# List SNS topics
aws sns list-topics

# Check topic attributes
aws sns get-topic-attributes --topic-arn "YOUR_TOPIC_ARN"
```

### **Discord Webhook Issues**
- Verify webhook URL is correct
- Check Discord channel permissions
- Test webhook manually:
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content": "Test message"}'
```

### **Terraform Issues**
```bash
# Check Terraform state
terraform show

# Refresh state
terraform refresh

# Plan changes
terraform plan
```

---

## 📈 **Best Practices**

### **Alert Fatigue Prevention**
- Set appropriate thresholds for each environment
- Use evaluation periods to avoid false positives
- Group related alerts
- Set up escalation policies

### **Monitoring Strategy**
- Start with critical alerts only
- Gradually add more monitoring
- Review and adjust thresholds regularly
- Monitor the monitors (Lambda health)

### **Cost Optimization**
- Use appropriate retention periods
- Monitor CloudWatch costs
- Use sampling for high-volume metrics
- Regular cleanup of unused resources

---

## 🔗 **Quick Links**

- **UAT SNS Topic**: `koneksi-uat-uat-discord-notifications`
- **Lambda Function**: `koneksi-uat-uat-discord-notifier`
- **CloudWatch Namespace**: `Koneksi/Application`
- **Discord Channel**: `#koneksi-alerts`

---

## 📞 **Support**

**Immediate Issues:**
1. Check CloudWatch logs
2. Test SNS topic manually
3. Verify Discord webhook
4. Review Terraform state

**Need Help?**
- Check this guide first
- Run deployment summary: `./deploy_all_environments.sh` → option 7
- Review CloudWatch metrics and alarms

---

## 🎉 **What's Next?**

1. ✅ **Deploy UAT monitoring** (webhook ready)
2. 🔄 **Set up staging webhook & deploy**
3. 🔧 **Integrate Go monitoring into backend**
4. 📊 **Create custom dashboards**
5. 👥 **Train team on Discord alerts**  
6. 🔄 **Set up alert escalation**
7. 📈 **Monitor and optimize thresholds**
8. 🚀 **Later: Add production environment**

---

**Ready to deploy? Run `./deploy_all_environments.sh` and choose your option!** 🚀 