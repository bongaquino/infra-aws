#!/bin/bash

# =============================================================================
# IPFS External Infrastructure Monitor
# Monitors IPFS external infrastructure from bootstrap node without hitting protected endpoints
# Checks: SSL certificates, DNS resolution, connectivity, nginx logs, container health
# Discord Channel: #bongaquino-alerts (same as staging/UAT)
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# IPFS Public Domains
IPFS_API_DOMAIN="ipfs.example.com"
IPFS_GATEWAY_DOMAIN="gateway.example.com"

# Discord Configuration (same as other monitoring)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
DISCORD_USERNAME="🌐 IPFS Infrastructure Monitor"
DISCORD_AVATAR_URL="https://ipfs.io/ipfs/QmYjtig7VJQ6XsnUjqqJvj7QaMcCAwtrgNdahSiFofrE7o"

# Monitoring Configuration
LOG_FILE="/tmp/ipfs-infrastructure-monitor.log"
STATE_DIR="/tmp/ipfs-infrastructure-monitoring"
TIMEOUT=10
CHECK_INTERVAL=300  # 5 minutes

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
    
    cat > /tmp/ipfs_infrastructure_alert.json << EOF
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
                "text": "IPFS Infrastructure Monitor"
            },
            "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        }
    ]
}
EOF

    if curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d @/tmp/ipfs_infrastructure_alert.json > /dev/null; then
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
# Infrastructure Health Check Functions
# =============================================================================

check_ssl_certificates() {
    log_message "Checking SSL certificates..."
    
    local previous_state=$(get_previous_state "ssl_certificates")
    local current_state="healthy"
    local issues=()
    local details=""
    
    for domain in "$IPFS_API_DOMAIN" "$IPFS_GATEWAY_DOMAIN"; do
        # Get SSL certificate info
        local cert_info=$(timeout $TIMEOUT openssl s_client -connect "$domain:443" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "FAILED")
        
        if [ "$cert_info" = "FAILED" ]; then
            issues+=("$domain: SSL certificate check failed")
            current_state="critical"
        else
            # Extract expiration date
            local not_after=$(echo "$cert_info" | grep "notAfter=" | cut -d= -f2)
            local exp_timestamp=$(date -d "$not_after" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local days_until_expiry=$(( (exp_timestamp - current_timestamp) / 86400 ))
            
            if [ $days_until_expiry -lt 7 ]; then
                issues+=("$domain: SSL certificate expires in $days_until_expiry days")
                current_state="critical"
            elif [ $days_until_expiry -lt 30 ]; then
                issues+=("$domain: SSL certificate expires in $days_until_expiry days")
                [ "$current_state" != "critical" ] && current_state="warning"
            fi
        fi
    done
    
    if [ ${#issues[@]} -eq 0 ]; then
        details=$(cat <<EOF
{
    "Status": "All SSL certificates valid",
    "API Domain": "$IPFS_API_DOMAIN",
    "Gateway Domain": "$IPFS_GATEWAY_DOMAIN",
    "Check Time": "$(date '+%Y-%m-%d %H:%M:%S UTC')"
}
EOF
)
        
        if [ "$previous_state" = "critical" ] || [ "$previous_state" = "warning" ]; then
            send_success_alert "SSL Certificates Recovered" "All SSL certificates are now valid" "$details"
        fi
        
        log_message "SSL Certificates: OK"
    else
        details=$(cat <<EOF
{
    "Status": "SSL certificate issues detected",
    "Issues": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]
}
EOF
)
        
        if [ "$previous_state" != "$current_state" ]; then
            if [ "$current_state" = "critical" ]; then
                send_critical_alert "SSL Certificate Issues" "Critical SSL certificate problems detected" "$details"
            else
                send_warning_alert "SSL Certificate Warning" "SSL certificates need attention" "$details"
            fi
        fi
        
        log_message "SSL Certificates: $current_state - ${#issues[@]} issues"
    fi
    
    set_current_state "ssl_certificates" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

check_dns_resolution() {
    log_message "Checking DNS resolution..."
    
    local previous_state=$(get_previous_state "dns_resolution")
    local current_state="healthy"
    local issues=()
    
    for domain in "$IPFS_API_DOMAIN" "$IPFS_GATEWAY_DOMAIN"; do
        local dns_result=$(timeout $TIMEOUT nslookup "$domain" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | head -1 | awk '{print $2}' || echo "FAILED")
        
        if [ "$dns_result" = "FAILED" ] || [ -z "$dns_result" ]; then
            issues+=("$domain: DNS resolution failed")
            current_state="critical"
        else
            log_message "DNS: $domain -> $dns_result"
        fi
    done
    
    local details=""
    if [ ${#issues[@]} -eq 0 ]; then
        details=$(cat <<EOF
{
    "Status": "DNS resolution working",
    "API Domain": "$IPFS_API_DOMAIN",
    "Gateway Domain": "$IPFS_GATEWAY_DOMAIN"
}
EOF
)
        
        if [ "$previous_state" = "critical" ]; then
            send_success_alert "DNS Resolution Recovered" "DNS resolution is working normally" "$details"
        fi
        
        log_message "DNS Resolution: OK"
    else
        details=$(cat <<EOF
{
    "Status": "DNS resolution issues",
    "Issues": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]
}
EOF
)
        
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "DNS Resolution Failed" "DNS resolution issues detected" "$details"
        fi
        
        log_message "DNS Resolution: FAILED - ${#issues[@]} issues"
    fi
    
    set_current_state "dns_resolution" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

check_connectivity() {
    log_message "Checking network connectivity..."
    
    local previous_state=$(get_previous_state "connectivity")
    local current_state="healthy"
    local issues=()
    
    for domain in "$IPFS_API_DOMAIN" "$IPFS_GATEWAY_DOMAIN"; do
        # Test HTTPS port connectivity
        if ! timeout $TIMEOUT nc -z "$domain" 443 2>/dev/null; then
            issues+=("$domain: HTTPS port 443 not reachable")
            current_state="critical"
        fi
        
        # Test HTTP port connectivity (should redirect)
        if ! timeout $TIMEOUT nc -z "$domain" 80 2>/dev/null; then
            issues+=("$domain: HTTP port 80 not reachable")
            current_state="critical"
        fi
    done
    
    local details=""
    if [ ${#issues[@]} -eq 0 ]; then
        details=$(cat <<EOF
{
    "Status": "Network connectivity OK",
    "Ports Tested": "80, 443",
    "API Domain": "$IPFS_API_DOMAIN",
    "Gateway Domain": "$IPFS_GATEWAY_DOMAIN"
}
EOF
)
        
        if [ "$previous_state" = "critical" ]; then
            send_success_alert "Network Connectivity Recovered" "Network connectivity is working" "$details"
        fi
        
        log_message "Network Connectivity: OK"
    else
        details=$(cat <<EOF
{
    "Status": "Network connectivity issues",
    "Issues": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]
}
EOF
)
        
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "Network Connectivity Failed" "Network connectivity issues detected" "$details"
        fi
        
        log_message "Network Connectivity: FAILED - ${#issues[@]} issues"
    fi
    
    set_current_state "connectivity" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

check_nginx_health() {
    log_message "Checking nginx container health..."
    
    local previous_state=$(get_previous_state "nginx_health")
    local current_state="healthy"
    local issues=()
    
    # Check if nginx container is running
    local nginx_status=$(docker ps --filter name=nginx --format '{{.Status}}' 2>/dev/null || echo "NOT_FOUND")
    if [ "$nginx_status" = "NOT_FOUND" ]; then
        issues+=("Nginx container not found")
        current_state="critical"
    elif ! echo "$nginx_status" | grep -q "Up"; then
        issues+=("Nginx container not running: $nginx_status")
        current_state="critical"
    fi
    
    # Check nginx error logs for recent issues
    local error_count=$(docker logs nginx --since="5m" 2>&1 | grep -i error | wc -l 2>/dev/null || echo "0")
    error_count=$(echo "$error_count" | tr -d '\n' | tr -d ' ')
    if [ "${error_count:-0}" -gt 10 ]; then
        issues+=("High error count in nginx logs: $error_count errors in last 5 minutes")
        [ "$current_state" != "critical" ] && current_state="warning"
    fi
    
    # Check for 5xx responses (server errors)
    local server_errors=$(docker logs nginx --since="5m" 2>&1 | grep -E " (500|502|503|504) " | wc -l 2>/dev/null || echo "0")
    server_errors=$(echo "$server_errors" | tr -d '\n' | tr -d ' ')
    if [ "${server_errors:-0}" -gt 5 ]; then
        issues+=("High server error count: $server_errors 5xx responses in last 5 minutes")
        current_state="critical"
    fi
    
    local details=""
    if [ ${#issues[@]} -eq 0 ]; then
        details=$(cat <<EOF
{
    "Status": "Nginx healthy",
    "Container Status": "$nginx_status",
    "Error Count (5m)": "$error_count",
    "Server Errors (5m)": "$server_errors"
}
EOF
)
        
        if [ "$previous_state" = "critical" ] || [ "$previous_state" = "warning" ]; then
            send_success_alert "Nginx Health Recovered" "Nginx container is healthy" "$details"
        fi
        
        log_message "Nginx Health: OK"
    else
        details=$(cat <<EOF
{
    "Status": "Nginx issues detected",
    "Container Status": "$nginx_status",
    "Issues": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]
}
EOF
)
        
        if [ "$previous_state" != "$current_state" ]; then
            if [ "$current_state" = "critical" ]; then
                send_critical_alert "Nginx Health Critical" "Critical nginx issues detected" "$details"
            else
                send_warning_alert "Nginx Health Warning" "Nginx health issues detected" "$details"
            fi
        fi
        
        log_message "Nginx Health: $current_state - ${#issues[@]} issues"
    fi
    
    set_current_state "nginx_health" "$current_state"
    return $([ "$current_state" = "healthy" ] && echo 0 || echo 1)
}

check_access_control_effectiveness() {
    log_message "Checking access control effectiveness..."
    
    local previous_state=$(get_previous_state "access_control")
    local current_state="healthy"
    
    # Count 403 responses (good - access control working)
    local forbidden_count=$(docker logs nginx --since="5m" 2>&1 | grep " 403 " | wc -l 2>/dev/null || echo "0")
    forbidden_count=$(echo "$forbidden_count" | tr -d '\n' | tr -d ' ')
    
    # Count successful API requests from external IPs (should be from whitelisted IPs only)
    local api_success_count=$(docker logs nginx --since="5m" 2>&1 | grep -E "/api/v0/.*\" 200" | wc -l 2>/dev/null || echo "0")
    api_success_count=$(echo "$api_success_count" | tr -d '\n' | tr -d ' ')
    
    local details=$(cat <<EOF
{
    "Status": "Access control monitoring",
    "Forbidden Requests (5m)": "$forbidden_count",
    "Successful API Requests (5m)": "$api_success_count",
    "Assessment": "$([ "${forbidden_count:-0}" -gt 0 ] && echo "Access control active" || echo "No blocked requests detected")"
}
EOF
)
    
    if [ "$previous_state" = "critical" ]; then
        send_success_alert "Access Control Recovered" "Access control monitoring restored" "$details"
    fi
    
    log_message "Access Control: OK - $forbidden_count blocked, $api_success_count allowed"
    
    set_current_state "access_control" "$current_state"
    return 0
}

# =============================================================================
# Health Summary Function
# =============================================================================

send_health_summary() {
    log_message "Sending IPFS infrastructure health summary..."
    
    # Get actual current health states
    local ssl_state=$(get_previous_state "ssl_certificates")
    local dns_state=$(get_previous_state "dns_resolution")
    local connectivity_state=$(get_previous_state "connectivity")
    local nginx_state=$(get_previous_state "nginx_health")
    local access_state=$(get_previous_state "access_control")
    
    # Count healthy services
    local healthy_count=0
    [ "$ssl_state" = "healthy" ] && ((healthy_count++))
    [ "$dns_state" = "healthy" ] && ((healthy_count++))
    [ "$connectivity_state" = "healthy" ] && ((healthy_count++))
    [ "$nginx_state" = "healthy" ] && ((healthy_count++))
    [ "$access_state" = "healthy" ] && ((healthy_count++))
    
    # Set color based on health status
    local color=65280    # Green for all healthy
    [ $healthy_count -lt 5 ] && color=16753920  # Orange for some issues
    [ $healthy_count -eq 0 ] && color=16711680  # Red for all failed
    
    # Build status display
    local ssl_icon=$([ "$ssl_state" = "healthy" ] && echo "✅" || echo "⚠️")
    local dns_icon=$([ "$dns_state" = "healthy" ] && echo "✅" || echo "⚠️")
    local net_icon=$([ "$connectivity_state" = "healthy" ] && echo "✅" || echo "⚠️")
    local nginx_icon=$([ "$nginx_state" = "healthy" ] && echo "✅" || echo "⚠️")
    local access_icon=$([ "$access_state" = "healthy" ] && echo "✅" || echo "⚠️")
    
    local ssl_text=$([ "$ssl_state" = "healthy" ] && echo "OK" || echo "Issues detected")
    local dns_text=$([ "$dns_state" = "healthy" ] && echo "OK" || echo "Issues detected") 
    local net_text=$([ "$connectivity_state" = "healthy" ] && echo "OK" || echo "Issues detected")
    local nginx_text=$([ "$nginx_state" = "healthy" ] && echo "OK" || echo "Issues detected")
    local access_text=$([ "$access_state" = "healthy" ] && echo "OK" || echo "Issues detected")
    
    # Create JSON payload file to avoid shell quoting issues
    cat > /tmp/infra_summary.json << EOF
{
    "username": "IPFS Infrastructure Monitor",
    "embeds": [{
        "title": "🌐 IPFS Infrastructure Monitor",
        "description": "$ssl_icon SSL Certificates: $ssl_text\n$dns_icon DNS Resolution: $dns_text\n$net_icon Network Connectivity: $net_text\n$nginx_icon Nginx Health: $nginx_text\n$access_icon Access Control: $access_text\n\n**Status: $healthy_count/5 healthy**",
        "color": $color,
        "footer": {
            "text": "Automated monitoring summary"
        },
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
    }]
}
EOF
    
    curl -X POST 'https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h' \
        -H 'Content-Type: application/json' \
        -d @/tmp/infra_summary.json > /dev/null && rm -f /tmp/infra_summary.json
    
    if [ $? -eq 0 ]; then
        log_message "Discord summary sent successfully"
    else
        log_message "Failed to send Discord summary"
    fi
}

# =============================================================================
# Main Functions
# =============================================================================

run_health_checks() {
    log_message "=== Starting IPFS infrastructure health checks ==="
    
    create_state_dir
    
    local ssl_result=0
    local dns_result=0
    local connectivity_result=0
    local nginx_result=0
    local access_result=0
    
    # Run all checks
    check_ssl_certificates || ssl_result=$?
    check_dns_resolution || dns_result=$?
    check_connectivity || connectivity_result=$?
    check_nginx_health || nginx_result=$?
    check_access_control_effectiveness || access_result=$?
    
    local total_issues=$((ssl_result + dns_result + connectivity_result + nginx_result + access_result))
    
    log_message "=== Infrastructure health checks completed: $((5 - total_issues))/5 passed ==="
    
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
    "ssl")
        create_state_dir
        check_ssl_certificates
        ;;
    "dns")
        create_state_dir
        check_dns_resolution
        ;;
    "connectivity")
        create_state_dir
        check_connectivity
        ;;
    "nginx")
        create_state_dir
        check_nginx_health
        ;;
    "access")
        create_state_dir
        check_access_control_effectiveness
        ;;
    *)
        echo "Usage: $0 {check|summary|ssl|dns|connectivity|nginx|access}"
        echo ""
        echo "Commands:"
        echo "  check         - Run all infrastructure health checks"
        echo "  summary       - Send health summary to Discord"
        
        echo "  ssl           - Check only SSL certificates"
        echo "  dns           - Check only DNS resolution"
        echo "  connectivity  - Check only network connectivity"
        echo "  nginx         - Check only nginx container health"
        echo "  access        - Check only access control effectiveness"
        exit 1
        ;;
esac 