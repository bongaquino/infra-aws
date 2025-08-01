# 🎯 Staging Environment Setup Guide

Complete staging setup for Discord monitoring - focused and streamlined!

## 🚀 **Quick Start for Staging**

### **Step 1: No Discord Setup Needed!**

✅ **Staging uses the same Discord webhook as UAT**
- Same channel: `#koneksi-alerts`
- Same webhook URL (already configured)
- Different bot name: `🟡 Koneksi Staging Bot`
- Ready to deploy immediately!

### **Step 2: Deploy Staging Monitoring**

```bash
cd koneksi-aws/discord_notifications
./deploy_all_environments.sh
```

**Choose option 2**: Deploy Staging only

No webhook URL needed - it will automatically use the same webhook as UAT!

### **Step 3: Test Staging**

After deployment, test with:

```bash
aws sns publish \
  --topic-arn "arn:aws:sns:ap-southeast-1:985869370256:koneksi-staging-staging-discord-notifications" \
  --message "🎯 Staging test message" \
  --subject "Staging Test"
```

---

## 🎨 **Staging vs UAT Differences**

| Feature | UAT | Staging |
|---------|-----|---------|
| **Discord Channel** | `#koneksi-alerts` | `#koneksi-alerts` (SAME) |
| **Webhook URL** | Configured | SAME as UAT |
| **Bot Name** | `🔵 Koneksi UAT Bot` | `🟡 Koneksi Staging Bot` |
| **Alert Colors** | Standard | Orange-tinted (staging) |
| **Thresholds** | Relaxed | Same as UAT |
| **SNS Topic** | `koneksi-uat-uat-discord-notifications` | `koneksi-staging-staging-discord-notifications` |

---

**Ready to set up staging? Create your Discord webhook and run the deployment script!** 🚀 