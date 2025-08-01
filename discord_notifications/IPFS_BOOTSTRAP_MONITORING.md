# 🔗 IPFS Bootstrap Node Incident Response Automation

## Overview

This monitoring solution provides **comprehensive incident response automation** for IPFS Bootstrap Node 01 (27.255.70.17) with automated Discord alerts, health checks, and recovery procedures.

## 🎯 Features

### 1. **Access Monitoring/Alerting**
- ✅ SSH connectivity monitoring
- ✅ Service availability checks
- ✅ Network connectivity verification
- ✅ Real-time Discord notifications

### 2. **Security Audits**
- ✅ Failed login attempt monitoring
- ✅ Firewall status verification
- ✅ Fail2ban service monitoring
- ✅ Automated security alerts

### 3. **Incident Response Automation**
- ✅ Automatic service restart
- ✅ Storage cleanup procedures
- ✅ Health recovery notifications
- ✅ Escalation to Discord channel

## 📋 Monitoring Coverage

### System Health
- **CPU Usage**: Alert when >80%
- **Memory Usage**: Alert when >85%
- **Disk Usage**: Alert when >90%
- **Response Time**: Alert when >5 seconds

### IPFS Services
- **IPFS Daemon**: Container status and API responsiveness
- **IPFS Cluster**: Cluster health and peer connectivity
- **Storage Health**: Repository verification and pin status
- **Network Connectivity**: Swarm peers and external connectivity

### Security
- **SSH Security**: Failed login monitoring
- **Firewall Status**: UFW configuration verification
- **Fail2ban**: Intrusion prevention monitoring

## 🚀 Quick Deployment

### 1. Deploy to Bootstrap Node

```bash
# Copy script to bootstrap node
scp koneksi-aws/discord_notifications/ipfs-bootstrap-monitor.sh ipfs@27.255.70.17:~/

# SSH to bootstrap node
ssh ipfs@27.255.70.17

# Make executable and setup monitoring
chmod +x ipfs-bootstrap-monitor.sh
./ipfs-bootstrap-monitor.sh setup
```

### 2. Test the Setup

```bash
# Test Discord connectivity
./ipfs-bootstrap-monitor.sh test

# Run manual health check
./ipfs-bootstrap-monitor.sh check

# Send health summary
./ipfs-bootstrap-monitor.sh summary
```

## 🔧 Configuration

### Discord Integration
- **Channel**: `#koneksi-alerts` (same as staging/UAT)
- **Webhook**: Uses existing koneksi webhook
- **Bot Name**: `🔗 IPFS Bootstrap Monitor`

### Monitoring Schedule
- **Health Checks**: Every 5 minutes
- **Daily Summary**: 8:00 AM UTC
- **Automatic**: Configured via cron jobs

## 📊 Alert Types

| Alert Type | Color | Trigger | Action |
|------------|-------|---------|---------|
| 🚨 **CRITICAL** | Red | Service down, SSH failure | Immediate attention required |
| ⚠️ **WARNING** | Orange | High resource usage, slow response | Monitor closely |
| ℹ️ **INFO** | Blue | Status updates, manual actions | Informational |
| ✅ **RESOLVED** | Green | Service recovery, issues fixed | Confirmation |

## 🛠️ Available Commands

```bash
# Primary commands
./ipfs-bootstrap-monitor.sh check      # Run health checks
./ipfs-bootstrap-monitor.sh summary    # Send health summary
./ipfs-bootstrap-monitor.sh test       # Test Discord alerts

# Incident response
./ipfs-bootstrap-monitor.sh restart    # Restart IPFS services
./ipfs-bootstrap-monitor.sh cleanup    # Clean up storage

# Setup
./ipfs-bootstrap-monitor.sh setup      # Install monitoring
```

## 🔄 Automated Recovery

### Service Restart
When IPFS services fail:
1. Automatically restart IPFS daemon
2. Restart IPFS cluster
3. Verify service health
4. Send recovery notifications

### Storage Cleanup
When storage issues detected:
1. Docker system cleanup
2. IPFS garbage collection
3. Repository optimization
4. Status confirmation

## 📱 Discord Notifications

### Sample Alert Format
```
🔗 IPFS Bootstrap Monitor

🚨 CRITICAL: IPFS Daemon Down
IPFS daemon container is not running

Server: IPFS Bootstrap Node 01 (27.255.70.17)
Timestamp: 2024-01-15 14:30:25 UTC
Message ID: 1705330225-4521
Details: Status: Container not found or stopped
```

### Recovery Notification
```
🔗 IPFS Bootstrap Monitor

✅ RESOLVED: IPFS Daemon Recovered
IPFS daemon is running normally

Server: IPFS Bootstrap Node 01 (27.255.70.17)
Timestamp: 2024-01-15 14:32:15 UTC
Message ID: 1705330335-7892
Details: Node ID: 12D3KooWRJRahRo8i..., Response time: 245ms
```

## 🔍 Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Check SSH key permissions
   chmod 600 ~/.ssh/id_rsa
   
   # Test manual connection
   ssh ipfs@27.255.70.17
   ```

2. **Discord Alerts Not Sending**
   ```bash
   # Test webhook manually
   curl -X POST "https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h" \
     -H "Content-Type: application/json" \
     -d '{"content": "Test message"}'
   ```

3. **Service Restart Failed**
   ```bash
   # Manual service restart
   cd /home/ipfs/koneksi-ipfs/docker-compose/koneksi-ipfs-kr-bootstrap-02
   docker-compose restart
   ```

### Log Locations
- **Monitor Log**: `/tmp/ipfs-bootstrap-monitor.log`
- **State Files**: `/tmp/ipfs-bootstrap-monitoring/`
- **IPFS Logs**: `docker logs ipfs`
- **Cluster Logs**: `docker logs ipfs-cluster`

## 🎛️ Advanced Configuration

### Customize Alert Thresholds
Edit the script variables:
```bash
CPU_THRESHOLD=80           # CPU usage alert %
MEMORY_THRESHOLD=85        # Memory usage alert %
DISK_THRESHOLD=90          # Disk usage alert %
RESPONSE_TIME_THRESHOLD=5000  # Response time alert (ms)
```

### Change Check Frequency
```bash
# Edit cron schedule (current: every 5 minutes)
crontab -e
# Change: */5 * * * * to */10 * * * * for 10-minute intervals
```

## 🚨 Emergency Procedures

### If Bootstrap Node is Down
1. **Immediate**: Check Discord alerts for details
2. **Assess**: SSH to server and check status
3. **Restart**: Use `./ipfs-bootstrap-monitor.sh restart`
4. **Escalate**: If restart fails, manual intervention required

### If Cluster is Unhealthy
1. **Check Peers**: `docker exec ipfs-cluster ipfs-cluster-ctl peers ls`
2. **Verify Connectivity**: Test network connections to peer nodes
3. **Restart Cluster**: `docker-compose restart ipfs-cluster`
4. **Re-sync**: Allow time for cluster synchronization

## 📞 Support

For issues with the monitoring system:
1. Check the monitor log: `tail -f /tmp/ipfs-bootstrap-monitor.log`
2. Review Discord channel for recent alerts
3. Test individual components using the script commands
4. If needed, disable monitoring temporarily: `crontab -r`

## 🔄 Maintenance

### Weekly Tasks
- [ ] Review Discord alerts for patterns
- [ ] Check log file sizes
- [ ] Verify cron jobs are running

### Monthly Tasks
- [ ] Update alert thresholds if needed
- [ ] Review false positive rates
- [ ] Test recovery procedures

---

**Status**: ✅ Ready for deployment  
**Environment**: Production IPFS Bootstrap Node  
**Monitoring**: 24/7 automated with Discord alerts  
**Recovery**: Automated incident response enabled 