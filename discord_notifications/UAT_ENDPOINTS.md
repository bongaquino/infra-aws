# 🔵 UAT Endpoints Documentation

## 📍 **UAT Environment URLs**

### **Primary Services**
- **Frontend (React App)**: `https://app-uat.koneksi.co.kr`
- **Backend API**: `https://uat.koneksi.co.kr/api`
- **MongoDB Admin**: `https://mongo-uat.koneksi.co.kr`

### **Infrastructure Endpoints**
- **ALB Main**: `koneksi-uat-alb-630040688.ap-southeast-1.elb.amazonaws.com`
- **ECS Cluster**: `koneksi-uat-cluster`
- **ECS Service**: `koneksi-uat-service`

### **Monitoring & Management**
- **Discord Bot**: `🔵 Koneksi UAT Bot`
- **Discord Channel**: `#koneksi-alerts`
- **SNS Topic**: `koneksi-uat-discord-notifications`
- **Lambda Function**: `koneksi-uat-discord-notifier`

## 🩺 **Health Check Endpoints**

### **Backend API Health**
```bash
curl -s https://uat.koneksi.co.kr/api/health | jq
```

**Expected Response:**
```json
{
  "status": "healthy",
  "environment": "uat",
  "timestamp": "2024-07-13T10:30:00.000Z",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

### **Frontend Availability**
```bash
curl -I https://app-uat.koneksi.co.kr
```

**Expected Response:**
```
HTTP/2 200 
content-type: text/html
```

### **MongoDB Admin Interface**
```bash
curl -I https://mongo-uat.koneksi.co.kr
```

**Expected Response:**
```
HTTP/2 200 
content-type: text/html
```

## 🧪 **Testing Commands**

### **Send Test Discord Alert**
```bash
aws sns publish --profile koneksi --region ap-southeast-1 \
  --topic-arn arn:aws:sns:ap-southeast-1:985869370256:koneksi-uat-discord-notifications \
  --message "UAT system test alert" \
  --subject "UAT Test"
```

### **Monitor Lambda Logs**
```bash
aws logs tail /aws/lambda/koneksi-uat-discord-notifier --profile koneksi --region ap-southeast-1 --follow
```

### **Check Service Status**
```bash
# ECS Service Status
aws ecs describe-services --profile koneksi --region ap-southeast-1 \
  --cluster koneksi-uat-cluster \
  --services koneksi-uat-service

# ALB Target Health
aws elbv2 describe-target-health --profile koneksi --region ap-southeast-1 \
  --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-1:985869370256:targetgroup/koneksi-uat-targets/xxx
```

## 📊 **Service Dependencies**

```mermaid
graph TD
    A[app-uat.koneksi.co.kr] --> B[uat.koneksi.co.kr/api]
    B --> C[MongoDB]
    B --> D[Redis]
    E[mongo-uat.koneksi.co.kr] --> C
    F[ALB] --> B
    G[Discord Bot] --> H[#koneksi-alerts]
    B --> I[SNS Topic]
    I --> J[Lambda Function]
    J --> G
```

## 🔍 **Troubleshooting**

### **Common Issues**

1. **Frontend Not Loading**
   ```bash
   # Check ALB health
   aws elbv2 describe-target-health --profile koneksi
   # Check ECS service
   aws ecs describe-services --profile koneksi --cluster koneksi-uat-cluster
   ```

2. **API Errors**
   ```bash
   # Check backend logs
   aws logs tail /aws/ecs/koneksi-uat --profile koneksi --follow
   ```

3. **MongoDB Connection Issues**
   ```bash
   # Check MongoDB admin interface
   curl -v https://mongo-uat.koneksi.co.kr
   ```

## 📈 **Monitoring URLs**

- **CloudWatch Dashboard**: [UAT Metrics](https://console.aws.amazon.com/cloudwatch)
- **ECS Console**: [koneksi-uat-cluster](https://console.aws.amazon.com/ecs/home?region=ap-southeast-1#/clusters/koneksi-uat-cluster)
- **ALB Console**: [koneksi-uat-alb](https://console.aws.amazon.com/ec2/v2/home?region=ap-southeast-1#LoadBalancers:)
- **Lambda Logs**: [koneksi-uat-discord-notifier](https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fkoneksi-uat-discord-notifier)

## 🚨 **Emergency Contacts**

- **Discord Channel**: `#koneksi-alerts`
- **Bot**: `🔵 Koneksi UAT Bot`
- **Environment**: `UAT`
- **Region**: `ap-southeast-1`

---

**Last Updated**: July 13, 2024  
**Environment**: UAT  
**Region**: ap-southeast-1 