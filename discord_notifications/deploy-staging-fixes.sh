#!/bin/bash

# =============================================================================
# Deploy Staging Server Monitoring Fixes
# =============================================================================

set -e

STAGING_SERVER="52.77.36.120"
STAGING_USER="ubuntu"
STAGING_MONITORING_DIR="/home/ubuntu/monitoring"

echo "🚀 Deploying fixed staging monitoring scripts to ${STAGING_SERVER}..."

# Create monitoring directory on staging server if it doesn't exist
echo "📁 Creating monitoring directory on staging server..."
ssh ${STAGING_USER}@${STAGING_SERVER} "mkdir -p ${STAGING_MONITORING_DIR}"

# Copy the fixed scripts to staging server
echo "📋 Copying fixed monitoring scripts..."
scp staging-server-monitor.sh ${STAGING_USER}@${STAGING_SERVER}:${STAGING_MONITORING_DIR}/
scp staging-baseline-monitor.sh ${STAGING_USER}@${STAGING_SERVER}:${STAGING_MONITORING_DIR}/
scp staging-server-monitor-clean.sh ${STAGING_USER}@${STAGING_SERVER}:${STAGING_MONITORING_DIR}/

# Make scripts executable
echo "🔧 Making scripts executable..."
ssh ${STAGING_USER}@${STAGING_SERVER} "chmod +x ${STAGING_MONITORING_DIR}/*.sh"

# Check current cron jobs
echo "📅 Checking current cron jobs..."
ssh ${STAGING_USER}@${STAGING_SERVER} "crontab -l" || echo "No cron jobs found"

# Test the main monitoring script
echo "🧪 Testing fixed monitoring script..."
ssh ${STAGING_USER}@${STAGING_SERVER} "${STAGING_MONITORING_DIR}/staging-server-monitor.sh summary"

echo "✅ Deployment completed! The next Daily Technical Health Report should now display as:"
echo "   'ℹ️ INFO: Staging Backend Health Summary'"
echo "   And JSON formatting should be clean and readable."

echo ""
echo "🕐 Next automatic report will be sent at 8:00 AM UTC"
echo "🧪 To test immediately, run: ssh ${STAGING_USER}@${STAGING_SERVER} '${STAGING_MONITORING_DIR}/staging-server-monitor.sh summary'" 