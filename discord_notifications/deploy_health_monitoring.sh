#!/bin/bash

# =============================================================================
# Health Endpoint Monitoring Deployment Script
# =============================================================================

set -e

# Configuration
REGION="ap-southeast-1"
PROFILE="koneksi"
ENVIRONMENT="uat"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check AWS profile
    if ! aws sts get-caller-identity --profile $PROFILE &> /dev/null; then
        print_error "AWS profile '$PROFILE' is not configured or invalid"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Test health endpoints
test_health_endpoint() {
    print_status "Testing health endpoints before setup..."
    
    ENDPOINTS=(
        "https://server-uat.koneksi.co.kr/check-health"
        "https://mongo-uat.koneksi.co.kr"
        "https://app-uat.koneksi.co.kr"
    )
    
    for ENDPOINT in "${ENDPOINTS[@]}"; do
        print_status "Testing $ENDPOINT..."
        
        # Use credentials for mongo endpoint
        if [[ "$ENDPOINT" == *"mongo-uat"* ]]; then
            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:koneksiPassw0rd" "$ENDPOINT" || echo "000")
        else
            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT" || echo "000")
        fi
        
        if [ "$HTTP_STATUS" = "200" ]; then
            print_success "✅ $ENDPOINT is responding (HTTP $HTTP_STATUS)"
            
            # Show response for server endpoint only
            if [[ "$ENDPOINT" == *"server-uat"* ]]; then
                RESPONSE=$(curl -s "$ENDPOINT")
                echo "Response: $RESPONSE"
                
                # Validate JSON structure
                if echo "$RESPONSE" | jq -e '.data.healthy == true' >/dev/null 2>&1; then
                    print_success "✅ Health endpoint returning healthy status"
                else
                    print_warning "⚠️  Health endpoint responding but status may be unhealthy"
                fi
            fi
        else
            print_error "❌ $ENDPOINT not responding (HTTP $HTTP_STATUS)"
        fi
    done
    
    print_warning "Continuing with setup - monitoring will detect when endpoints are available"
}

# Deploy infrastructure
deploy_monitoring() {
    print_status "Deploying health endpoint monitoring..."
    
    # Change to environment directory
    cd envs/$ENVIRONMENT
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan \
        -var-file="terraform.tfvars" \
        -target=aws_synthetics_canary.health_endpoint \
        -target=aws_cloudwatch_metric_alarm.canary_success_rate \
        -target=aws_cloudwatch_metric_alarm.canary_duration \
        -target=aws_cloudwatch_metric_alarm.canary_failed \
        -target=aws_cloudwatch_metric_alarm.unhealthy_response
    
    # Apply deployment
    print_status "Applying Terraform deployment..."
    terraform apply \
        -var-file="terraform.tfvars" \
        -target=aws_synthetics_canary.health_endpoint \
        -target=aws_cloudwatch_metric_alarm.canary_success_rate \
        -target=aws_cloudwatch_metric_alarm.canary_duration \
        -target=aws_cloudwatch_metric_alarm.canary_failed \
        -target=aws_cloudwatch_metric_alarm.unhealthy_response \
        -auto-approve
    
    # Return to original directory
    cd ../..
    
    print_success "Health endpoint monitoring deployed successfully!"
}

# Send test alert
send_test_alert() {
    print_status "Sending test Discord notification..."
    
    SNS_TOPIC_ARN="arn:aws:sns:$REGION:985869370256:koneksi-$ENVIRONMENT-discord-notifications"
    
    TEST_MESSAGE=$(cat <<EOF
{
  "title": "🏥 Health Monitoring Activated",
  "description": "UAT health endpoint monitoring is now active",
  "type": "success",
  "details": {
    "Endpoints": [
      "https://server-uat.koneksi.co.kr/check-health",
      "https://mongo-uat.koneksi.co.kr",
      "https://app-uat.koneksi.co.kr"
    ],
    "Check Frequency": "Every 5 minutes",
    "Canary Name": "koneksi-uat-health-monitor",
    "Environment": "uat",
    "Alert Types": [
      "🚨 Endpoint down/unreachable",
      "⚠️ High response time (>10s)",
      "🚨 Unhealthy status response",
      "📊 Success rate below 80%"
    ]
  }
}
EOF
)
    
    aws sns publish \
        --region "$REGION" \
        --profile "$PROFILE" \
        --topic-arn "$SNS_TOPIC_ARN" \
        --message "$TEST_MESSAGE" \
        --subject "Health Monitoring Setup Complete"
    
    print_success "Test notification sent to Discord!"
}

# Show monitoring details
show_monitoring_info() {
    print_status "Health Endpoint Monitoring Summary:"
    echo ""
    echo "📊 Monitoring Details:"
    echo "  • Endpoints:"
    echo "    - https://server-uat.koneksi.co.kr/check-health"
    echo "    - https://mongo-uat.koneksi.co.kr"
    echo "    - https://app-uat.koneksi.co.kr"
    echo "  • Check Frequency: Every 5 minutes"
    echo "  • Canary Name: koneksi-uat-health-monitor"
    echo "  • Timeout: 60 seconds"
    echo ""
    echo "🚨 Alert Conditions:"
    echo "  • Success rate below 80% (2 consecutive failures)"
    echo "  • Response time above 10 seconds (3 consecutive checks)"
    echo "  • Any check failure (immediate alert)"
    echo "  • Unhealthy status in response (immediate alert)"
    echo ""
    echo "📱 Discord Notifications:"
    echo "  • Channel: #koneksi-alerts"
    echo "  • Bot: 🔵 Koneksi UAT Bot"
    echo "  • SNS Topic: koneksi-uat-discord-notifications"
    echo ""
    echo "🔗 AWS Console Links:"
    echo "  • CloudWatch Synthetics: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#synthetics:canary/detail/koneksi-uat-health-monitor"
    echo "  • CloudWatch Alarms: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
    echo "  • Canary Logs: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/\$252Faws\$252Flambda\$252Fcwsyn-koneksi-uat-health-monitor"
    echo ""
    
    print_success "Health endpoint monitoring is now active!"
    print_warning "First results will appear in 5-10 minutes"
}

# Main deployment function
main() {
    echo "🏥 Koneksi UAT Health Endpoint Monitoring Setup"
    echo "=============================================="
    echo ""
    
    check_prerequisites
    test_health_endpoint
    deploy_monitoring
    send_test_alert
    show_monitoring_info
    
    echo ""
    print_success "🎉 Health endpoint monitoring setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor Discord channel for test notification"
    echo "2. Wait 5-10 minutes for first health check results"
    echo "3. Verify monitoring in AWS CloudWatch Synthetics console"
    echo ""
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "test-endpoint")
        test_health_endpoint
        ;;
    "test-alert")
        send_test_alert
        ;;
    "info")
        show_monitoring_info
        ;;
    *)
        echo "Usage: $0 {deploy|test-endpoint|test-alert|info}"
        echo ""
        echo "Commands:"
        echo "  deploy        - Full deployment (default)"
        echo "  test-endpoint - Test health endpoint only"
        echo "  test-alert    - Send test Discord notification"
        echo "  info          - Show monitoring information"
        exit 1
        ;;
esac 