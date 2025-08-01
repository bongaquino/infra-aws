#!/bin/bash

# =============================================================================
# IPFS External Endpoints Monitor
# Monitors public IPFS endpoints from external perspective
# Discord Channel: #koneksi-alerts (same as staging/UAT)
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# IPFS Public Endpoints
IPFS_API_URL="https://ipfs.koneksi.co.kr/api/v0/version"
IPFS_GATEWAY_URL="https://gateway.koneksi.co.kr"

# Test Content (Known CID that should exist)
TEST_CID="QmYjtig7VJQ6XsnUjqqJvj7QaMcCAwtrgNdahSiFofrE7o"
GATEWAY_TEST_URL="$IPFS_GATEWAY_URL/ipfs/$TEST_CID"

# Discord Configuration (same as other monitoring)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
DISCORD_USERNAME="🌐 IPFS Endpoints Monitor"
DISCORD_AVATAR_URL="https://ipfs.io/ipfs/QmYjtig7VJQ6XsnUjqqJvj7QaMcCAwtrgNdahSiFofrE7o"

# Monitoring Configuration
LOG_FILE="/tmp/ipfs-endpoints-monitor.log"
STATE_DIR="/tmp/ipfs-endpoints-monitoring"
TIMEOUT=15  # 15 second timeout for endpoint tests
CHECK_INTERVAL=300  # 5 minutes
MAX_RETRIES=3

# Performance Thresholds
API_RESPONSE_THRESHOLD=5000    # 5 seconds for API
GATEWAY_RESPONSE_THRESHOLD=10000  # 10 seconds for Gateway

# Standard Discord Colors (matching other monitoring)
COLOR_RED=15158332      # Critical/Error
COLOR_ORANGE=16776960   # Warning
COLOR_GREEN=65280       # Success
COLOR_BLUE=3447003      # Info

# =============================================================================
# Utility Functions
# =============================================================================

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

create_state_dir() {
    mkdir -p "$STATE_DIR"
}

get_previous_state() {
    local service="$1"
    local state_file="$STATE_DIR/${service}_state"
    [ -f "$state_file" ] && cat "$state_file" || echo "unknown"
}

set_current_state() {
    local service="$1"
    local state="$2"
    local state_file="$STATE_DIR/${service}_state"
    echo "$state" > "$state_file"
}

# =============================================================================
# Discord Notification Functions
# =============================================================================

send_discord_alert() {
    local title="$1"
    local description="$2"
    local color="$3"
    local details="$4"
    
    local message_id="$(date +%s)-$(jot -r 1 1000 9999 2>/dev/null || echo $RANDOM)"
    
    cat > /tmp/ipfs_endpoints_alert.json << EOF
{
    "username": "$DISCORD_USERNAME",
    "avatar_url": "$DISCORD_AVATAR_URL",
    "embeds": [
        {
            "title": "$title",
            "description": "$description",
            "color": $color,
            "fields": [
                {
                    "name": "📊 Details",
                    "value": "\`\`\`json\n$details\n\`\`\`",
                    "inline": false
                },
                {
                    "name": "🕒 Timestamp",
                    "value": "$(date '+%Y-%m-%d %H:%M:%S UTC')",
                    "inline": true
                },
                {
                    "name": "🆔 Message ID",
                    "value": "$message_id",
                    "inline": true
                }
            ],
            "footer": {
                "text": "IPFS External Endpoints Monitor"
            },
            "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        }
    ]
}
EOF

    if curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d @/tmp/ipfs_endpoints_alert.json > /dev/null; then
        log_message "Discord alert sent successfully: $title (ID: $message_id)"
        return 0
    else
        log_message "Failed to send Discord alert: $title"
        return 1
    fi
}

send_critical_alert() {
    send_discord_alert "🚨 $1" "$2" "$COLOR_RED" "$3"
}

send_warning_alert() {
    send_discord_alert "⚠️ $1" "$2" "$COLOR_ORANGE" "$3"
}

send_success_alert() {
    send_discord_alert "✅ $1" "$2" "$COLOR_GREEN" "$3"
}

send_info_alert() {
    send_discord_alert "ℹ️ $1" "$2" "$COLOR_BLUE" "$3"
}

# =============================================================================
# IPFS Endpoint Health Check Functions
# =============================================================================

check_ipfs_api() {
    log_message "Checking IPFS API endpoint..."
    
    local previous_state=$(get_previous_state "ipfs_api")
    local start_time=$(date +%s%3N)
    
    # Test IPFS API endpoint
    local response=$(curl -s -w "%{http_code}:%{time_total}" \
        --max-time $TIMEOUT \
        -X POST \
        "$IPFS_API_URL" 2>/dev/null || echo "TIMEOUT:$TIMEOUT")
    
    local end_time=$(date +%s%3N)
    
    # Parse response: format is "body\nHTTP_CODE:TIME"
    local status_line="${response##*$'\n'}"  # Get last line
    local http_code="${status_line%:*}"      # Get part before :
    local response_time="${status_line##*:}" # Get part after :
    local body="${response%$'\n'*}"          # Get everything before last newline
    
    # Convert response time to milliseconds if it's in seconds
    if [[ "$response_time" == *"."* ]]; then
        response_time=$(echo "scale=0; $response_time * 1000 / 1" | bc -l 2>/dev/null || echo "0")
    fi
    
    local current_state="healthy"
    local details=""
    
    if [ "$http_code" = "200" ] && [ "$response_time" -lt "$API_RESPONSE_THRESHOLD" ]; then
        current_state="healthy"
        details=$(cat <<EOF
{
    "Endpoint": "$IPFS_API_URL",
    "HTTP Status": "$http_code",
    "Response Time": "${response_time}ms",
    "Status": "Healthy",
    "API Version": "$(echo "$body" | grep -o '"Version":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo 'Unknown')"
}
EOF
)
        
        if [ "$previous_state" = "critical" ] || [ "$previous_state" = "warning" ]; then
            send_success_alert "IPFS API Recovered" "IPFS API endpoint is now responding normally" "$details"
        fi
        
        log_message "IPFS API: OK - ${response_time}ms"
    elif [ "$http_code" = "200" ]; then
        current_state="warning"
        details=$(cat <<EOF
{
    "Endpoint": "$IPFS_API_URL",
    "HTTP Status": "$http_code",
    "Response Time": "${response_time}ms",
    "Status": "Slow Response",
    "Threshold": "${API_RESPONSE_THRESHOLD}ms"
}
EOF
)
        
        if [ "$previous_state" != "warning" ]; then
            send_warning_alert "IPFS API Slow" "IPFS API responding slowly" "$details"
        fi
        
        log_message "IPFS API: SLOW - ${response_time}ms (threshold: ${API_RESPONSE_THRESHOLD}ms)"
    else
        current_state="critical"
        details=$(cat <<EOF
{
    "Endpoint": "$IPFS_API_URL",
    "HTTP Status": "$http_code",
    "Response Time": "${response_time}ms",
    "Status": "Failed",
    "Error": "$([ "$http_code" = "TIMEOUT" ] && echo "Connection timeout" || echo "HTTP error $http_code")"
}
EOF
)
        
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS API Down" "IPFS API endpoint is not responding" "$details"
        fi
        
        log_message "IPFS API: FAILED - $http_code (${response_time}ms)"
    fi
    
    set_current_state "ipfs_api" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

check_ipfs_gateway() {
    log_message "Checking IPFS Gateway endpoint..."
    
    local previous_state=$(get_previous_state "ipfs_gateway")
    local start_time=$(date +%s%3N)
    
    # Test IPFS Gateway with a test CID
    local response=$(curl -s -w "%{http_code}:%{time_total}" \
        --max-time $TIMEOUT \
        "$GATEWAY_TEST_URL" 2>/dev/null || echo "TIMEOUT:$TIMEOUT")
    
    local end_time=$(date +%s%3N)
    
    # Parse response: format is "body\nHTTP_CODE:TIME"
    local status_line="${response##*$'\n'}"  # Get last line
    local http_code="${status_line%:*}"      # Get part before :
    local response_time="${status_line##*:}" # Get part after :
    
    # Convert response time to milliseconds
    if [[ "$response_time" == *"."* ]]; then
        response_time=$(echo "scale=0; $response_time * 1000 / 1" | bc -l 2>/dev/null || echo "0")
    fi
    
    local current_state="healthy"
    local details=""
    
    if [ "$http_code" = "200" ] && [ "$response_time" -lt "$GATEWAY_RESPONSE_THRESHOLD" ]; then
        current_state="healthy"
        details=$(cat <<EOF
{
    "Endpoint": "$GATEWAY_TEST_URL",
    "HTTP Status": "$http_code",
    "Response Time": "${response_time}ms",
    "Status": "Healthy",
    "Test CID": "$TEST_CID"
}
EOF
)
        
        if [ "$previous_state" = "critical" ] || [ "$previous_state" = "warning" ]; then
            send_success_alert "IPFS Gateway Recovered" "IPFS Gateway is now responding normally" "$details"
        fi
        
        log_message "IPFS Gateway: OK - ${response_time}ms"
    elif [ "$http_code" = "200" ]; then
        current_state="warning"
        details=$(cat <<EOF
{
    "Endpoint": "$GATEWAY_TEST_URL",
    "HTTP Status": "$http_code",
    "Response Time": "${response_time}ms",
    "Status": "Slow Response",
    "Threshold": "${GATEWAY_RESPONSE_THRESHOLD}ms"
}
EOF
)
        
        if [ "$previous_state" != "warning" ]; then
            send_warning_alert "IPFS Gateway Slow" "IPFS Gateway responding slowly" "$details"
        fi
        
        log_message "IPFS Gateway: SLOW - ${response_time}ms (threshold: ${GATEWAY_RESPONSE_THRESHOLD}ms)"
    else
        current_state="critical"
        details=$(cat <<EOF
{
    "Endpoint": "$GATEWAY_TEST_URL",
    "HTTP Status": "$http_code",
    "Response Time": "${response_time}ms",
    "Status": "Failed",
    "Error": "$([ "$http_code" = "TIMEOUT" ] && echo "Connection timeout" || echo "HTTP error $http_code")"
}
EOF
)
        
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS Gateway Down" "IPFS Gateway is not responding" "$details"
        fi
        
        log_message "IPFS Gateway: FAILED - $http_code (${response_time}ms)"
    fi
    
    set_current_state "ipfs_gateway" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

check_access_control() {
    log_message "Checking IPFS access control..."
    
    local previous_state=$(get_previous_state "ipfs_access_control")
    
    # Test that the API root returns 403/404 (access control working)
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 10 \
        "https://ipfs.koneksi.co.kr/" 2>/dev/null || echo "TIMEOUT")
    
    local current_state="healthy"
    local details=""
    
    if [ "$response" = "404" ] || [ "$response" = "403" ]; then
        current_state="healthy"
        details=$(cat <<EOF
{
    "Endpoint": "https://ipfs.koneksi.co.kr/",
    "HTTP Status": "$response",
    "Status": "Access Control Working",
    "Expected": "403 or 404"
}
EOF
)
        
        if [ "$previous_state" = "critical" ]; then
            send_success_alert "IPFS Access Control Recovered" "Access control is working properly" "$details"
        fi
        
        log_message "IPFS Access Control: OK - HTTP $response"
    else
        current_state="critical"
        details=$(cat <<EOF
{
    "Endpoint": "https://ipfs.koneksi.co.kr/",
    "HTTP Status": "$response",
    "Status": "Access Control Issue",
    "Expected": "403 or 404",
    "Risk": "Potential unauthorized access"
}
EOF
)
        
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS Access Control Issue" "Unexpected access control behavior" "$details"
        fi
        
        log_message "IPFS Access Control: ISSUE - HTTP $response (expected 403/404)"
    fi
    
    set_current_state "ipfs_access_control" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

# =============================================================================
# Health Summary Function
# =============================================================================

send_health_summary() {
    log_message "Sending IPFS endpoints health summary..."
    
    local api_state=$(get_previous_state "ipfs_api")
    local gateway_state=$(get_previous_state "ipfs_gateway") 
    local access_state=$(get_previous_state "ipfs_access_control")
    
    local total_checks=3
    local healthy_checks=0
    
    [ "$api_state" = "healthy" ] && ((healthy_checks++))
    [ "$gateway_state" = "healthy" ] && ((healthy_checks++))
    [ "$access_state" = "healthy" ] && ((healthy_checks++))
    
    local overall_status="HEALTHY"
    local color=$COLOR_GREEN
    
    if [ $healthy_checks -lt $total_checks ]; then
        if [ $healthy_checks -eq 0 ]; then
            overall_status="CRITICAL"
            color=$COLOR_RED
        else
            overall_status="ISSUES"
            color=$COLOR_ORANGE
        fi
    fi
    
    local details=$(cat <<EOF
{
    "Overall Status": "$overall_status ($healthy_checks/$total_checks healthy)",
    "IPFS API": "$api_state",
    "IPFS Gateway": "$gateway_state", 
    "Access Control": "$access_state",
    "API Endpoint": "$IPFS_API_URL",
    "Gateway Endpoint": "$IPFS_GATEWAY_URL",
    "Check Time": "$(date '+%Y-%m-%d %H:%M:%S UTC')"
}
EOF
)
    
    send_discord_alert "IPFS Endpoints Health Summary" \
        "Daily health report for IPFS public endpoints" \
        "$color" "$details"
}

# =============================================================================
# Main Functions
# =============================================================================

run_health_checks() {
    log_message "=== Starting IPFS endpoints health checks ==="
    
    create_state_dir
    
    local api_result=0
    local gateway_result=0
    local access_result=0
    
    # Run all checks
    check_ipfs_api || api_result=$?
    check_ipfs_gateway || gateway_result=$?
    check_access_control || access_result=$?
    
    local total_issues=$((api_result + gateway_result + access_result))
    
    log_message "=== Health checks completed: $((3 - total_issues))/3 passed ==="
    
    return $total_issues
}

# =============================================================================
# Command Processing
# =============================================================================

case "${1:-check}" in
    "check")
        run_health_checks
        ;;
    "summary")
        send_health_summary
        ;;
    "api")
        create_state_dir
        check_ipfs_api
        ;;
    "gateway")
        create_state_dir
        check_ipfs_gateway
        ;;
    "access")
        create_state_dir
        check_access_control
        ;;
    *)
        echo "Usage: $0 {check|summary|api|gateway|access}"
        echo ""
        echo "Commands:"
        echo "  check     - Run all health checks"
        echo "  summary   - Send health summary to Discord"
        
        echo "  api       - Check only IPFS API endpoint"
        echo "  gateway   - Check only IPFS Gateway endpoint"
        echo "  access    - Check only access control"
        exit 1
        ;;
esac 