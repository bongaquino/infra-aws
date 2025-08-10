#!/bin/bash

# Generate logs for both ALBs
# This script will make requests to both ALBs for 1 minute to generate real logs

MAIN_ALB="bongaquino-uat-alb-1965161443.ap-southeast-1.elb.amazonaws.com"
SERVICES_ALB="bongaquino-uat-alb-services-835893911.ap-southeast-1.elb.amazonaws.com"

echo "🚀 Starting log generation for 1 minute..."
echo "📊 Main ALB: $MAIN_ALB"
echo "📊 Services ALB: $SERVICES_ALB"
echo "⏱️  Duration: 1 minute"
echo ""

# Function to make requests to an ALB
make_requests() {
    local alb_dns=$1
    local alb_name=$2
    
    echo "🔄 Generating traffic to $alb_name..."
    
    # Health check endpoint
    curl -s -o /dev/null -w "Health Check: %{http_code}\n" "http://$alb_dns/" &
    
    # API endpoints (these might return 404 but will still generate logs)
    curl -s -o /dev/null -w "API /api: %{http_code}\n" "http://$alb_dns/api" &
    curl -s -o /dev/null -w "API /api/health: %{http_code}\n" "http://$alb_dns/api/health" &
    curl -s -o /dev/null -w "API /api/users: %{http_code}\n" "http://$alb_dns/api/users" &
    
    # Random paths to generate various log entries
    curl -s -o /dev/null -w "Random /test: %{http_code}\n" "http://$alb_dns/test" &
    curl -s -o /dev/null -w "Random /admin: %{http_code}\n" "http://$alb_dns/admin" &
    curl -s -o /dev/null -w "Random /docs: %{http_code}\n" "http://$alb_dns/docs" &
    
    # POST requests to generate different log patterns
    curl -s -o /dev/null -w "POST /api/data: %{http_code}\n" -X POST "http://$alb_dns/api/data" &
    
    # Wait for all background requests to complete
    wait
}

# Start time
start_time=$(date +%s)
end_time=$((start_time + 60))  # 1 minute

echo "⏰ Started at: $(date)"
echo "⏰ Will end at: $(date -d @$end_time)"
echo ""

# Generate traffic for 1 minute
while [ $(date +%s) -lt $end_time ]; do
    # Make requests to both ALBs
    make_requests "$MAIN_ALB" "Main ALB"
    make_requests "$SERVICES_ALB" "Services ALB"
    
    # Small delay between batches
    sleep 2
    
    # Show progress
    elapsed=$(( $(date +%s) - start_time ))
    remaining=$(( 60 - elapsed ))
    echo "⏱️  Progress: ${elapsed}s elapsed, ${remaining}s remaining"
done

echo ""
echo "✅ Log generation complete!"
echo "📁 Check S3 bucket: bongaquino-uat-alb-logs"
echo "📊 Check CloudWatch Log Groups:"
echo "   - /aws/applicationloadbalancer/bongaquino-uat-main-alb/access-logs"
echo "   - /aws/applicationloadbalancer/bongaquino-uat-main-alb/connection-logs"
echo "   - /aws/applicationloadbalancer/bongaquino-uat-services-alb/access-logs"
echo "   - /aws/applicationloadbalancer/bongaquino-uat-services-alb/connection-logs"
echo ""
echo "🔍 You can check the logs in a few minutes after Lambda processing..." 