#!/bin/bash

# =============================================================================
# IPFS Bootstrap Node Monitoring Deployment Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BOOTSTRAP_IP="27.255.70.17"
SSH_USER="ipfs"
SCRIPT_NAME="ipfs-bootstrap-monitor.sh"
REMOTE_PATH="/home/$SSH_USER/$SCRIPT_NAME"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🔗 IPFS Bootstrap Node Monitoring Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Test SSH connectivity
test_ssh_connection() {
    print_status "Testing SSH connection to $SSH_USER@$BOOTSTRAP_IP..."
    
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$BOOTSTRAP_IP" "echo 'SSH connection successful'"; then
        print_success "SSH connection established"
        return 0
    else
        print_error "SSH connection failed"
        echo "Please ensure:"
        echo "1. SSH key is properly configured"
        echo "2. Server is accessible"
        echo "3. User '$SSH_USER' exists on the server"
        return 1
    fi
}

# Deploy monitoring script
deploy_script() {
    print_status "Deploying monitoring script..."
    
    # Copy script to server
    if scp -o StrictHostKeyChecking=no "$SCRIPT_NAME" "$SSH_USER@$BOOTSTRAP_IP:$REMOTE_PATH"; then
        print_success "Script copied successfully"
    else
        print_error "Failed to copy script"
        return 1
    fi
    
    # Make script executable
    if ssh "$SSH_USER@$BOOTSTRAP_IP" "chmod +x $REMOTE_PATH"; then
        print_success "Script made executable"
    else
        print_error "Failed to make script executable"
        return 1
    fi
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring on bootstrap node..."
    
    # Run setup command
    if ssh "$SSH_USER@$BOOTSTRAP_IP" "$REMOTE_PATH setup"; then
        print_success "Monitoring setup completed"
    else
        print_error "Failed to setup monitoring"
        return 1
    fi
}

# Test monitoring
test_monitoring() {
    print_status "Testing monitoring system..."
    
    # Send test alert
    if ssh "$SSH_USER@$BOOTSTRAP_IP" "$REMOTE_PATH test"; then
        print_success "Test alert sent successfully"
        print_warning "Check Discord channel #bongaquino-alerts for the test message"
    else
        print_error "Failed to send test alert"
        return 1
    fi
    
    # Run health check
    print_status "Running initial health check..."
    if ssh "$SSH_USER@$BOOTSTRAP_IP" "$REMOTE_PATH check"; then
        print_success "Health check completed"
    else
        print_warning "Health check reported issues - check Discord for alerts"
    fi
}

# Show status
show_status() {
    echo ""
    print_success "✅ IPFS Bootstrap Node Monitoring Deployed Successfully!"
    echo ""
    echo -e "${YELLOW}📊 Monitoring Details:${NC}"
    echo "  • Server: $BOOTSTRAP_IP"
    echo "  • User: $SSH_USER"
    echo "  • Script: $REMOTE_PATH"
    echo "  • Health Checks: Every 5 minutes"
    echo "  • Daily Summary: 8:00 AM UTC"
    echo "  • Discord Channel: #bongaquino-alerts"
    echo ""
    echo -e "${YELLOW}🛠️ Available Commands:${NC}"
    echo "  ssh $SSH_USER@$BOOTSTRAP_IP '$REMOTE_PATH check'      # Run health checks"
    echo "  ssh $SSH_USER@$BOOTSTRAP_IP '$REMOTE_PATH summary'    # Send health summary"
    echo "  ssh $SSH_USER@$BOOTSTRAP_IP '$REMOTE_PATH restart'    # Restart IPFS services"
    echo "  ssh $SSH_USER@$BOOTSTRAP_IP '$REMOTE_PATH cleanup'    # Clean up storage"
    echo ""
    echo -e "${YELLOW}📱 Discord Notifications:${NC}"
    echo "  • 🚨 CRITICAL: Service failures, SSH issues"
    echo "  • ⚠️ WARNING: High resource usage, slow response"
    echo "  • ℹ️ INFO: Status updates, manual actions"
    echo "  • ✅ RESOLVED: Service recovery, issues fixed"
    echo ""
}

# Main deployment function
main() {
    print_header
    
    # Check if script exists
    if [ ! -f "$SCRIPT_NAME" ]; then
        print_error "Monitoring script '$SCRIPT_NAME' not found in current directory"
        echo "Please run this script from the bongaquino-aws/discord_notifications directory"
        exit 1
    fi
    
    # Execute deployment steps
    if test_ssh_connection; then
        if deploy_script; then
            if setup_monitoring; then
                if test_monitoring; then
                    show_status
                    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
                else
                    print_warning "Monitoring deployed but testing failed"
                    echo "Please check the system manually"
                fi
            else
                print_error "Deployment failed at setup stage"
                exit 1
            fi
        else
            print_error "Deployment failed at copy stage"
            exit 1
        fi
    else
        print_error "Deployment failed at connection stage"
        exit 1
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "test")
        print_status "Testing existing monitoring..."
        ssh "$SSH_USER@$BOOTSTRAP_IP" "$REMOTE_PATH test"
        ;;
    "check")
        print_status "Running health check..."
        ssh "$SSH_USER@$BOOTSTRAP_IP" "$REMOTE_PATH check"
        ;;
    "summary")
        print_status "Sending health summary..."
        ssh "$SSH_USER@$BOOTSTRAP_IP" "$REMOTE_PATH summary"
        ;;
    "status")
        print_status "Checking monitoring status..."
        ssh "$SSH_USER@$BOOTSTRAP_IP" "crontab -l | grep ipfs-bootstrap-monitor || echo 'No cron jobs found'"
        ssh "$SSH_USER@$BOOTSTRAP_IP" "tail -n 20 /tmp/ipfs-bootstrap-monitor.log 2>/dev/null || echo 'No log file found'"
        ;;
    *)
        echo "Usage: $0 {deploy|test|check|summary|status}"
        echo "  deploy  - Deploy monitoring to bootstrap node (default)"
        echo "  test    - Send test alert"
        echo "  check   - Run health check"
        echo "  summary - Send health summary"
        echo "  status  - Check monitoring status"
        exit 1
        ;;
esac 