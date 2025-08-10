#!/bin/bash

# =============================================================================
# Staging Server Baseline Monitoring Script
# Server: 52.77.36.120 (Backend Server)
# Discord Channel: #bongaquino-alerts
# Focus: Core business services only
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Server Configuration
AWS_REGION="ap-southeast-1"
ENVIRONMENT="staging"
SERVICE="bongaquino-backend"
SERVER_IP="52.77.36.120"
LOG_FILE="/var/log/bongaquino-baseline-monitor.log"
STATE_DIR="/tmp/bongaquino-baseline-monitoring"

# Create directories
mkdir -p "$STATE_DIR"
sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# CloudWatch namespaces
SERVER_NAMESPACE="bongaquino/Server"
APP_NAMESPACE="bongaquino/Application"

# Alert thresholds
CPU_THRESHOLD=70
MEMORY_THRESHOLD=70
DISK_THRESHOLD=80
API_RESPONSE_THRESHOLD=5000  # 5 seconds

# =============================================================================
# Utility Functions
# =============================================================================

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

get_previous_state() {
    local service="$1"
    local state_file="$STATE_DIR/${service}.state"
    [ -f "$state_file" ] && cat "$state_file" || echo "unknown"
}

set_current_state() {
    local service="$1" 
    local state="$2"
    local state_file="$STATE_DIR/${service}.state"
    echo "$state" > "$state_file"
}

# Send metric to CloudWatch
send_metric() {
    local namespace="$1"
    local metric_name="$2"
    local value="$3"
    local unit="$4"
    local dimensions_json="$5"
    
    aws cloudwatch put-metric-data \
        --region "$AWS_REGION" \
        --namespace "$namespace" \
        --metric-data "[{\"MetricName\":\"$metric_name\",\"Value\":$value,\"Unit\":\"$unit\",\"Dimensions\":$dimensions_json}]" \
        >> "$LOG_FILE" 2>&1
}

# Send Discord alert via SNS
send_discord_alert() {
    local title="$1"
    local description="$2"
    local alert_type="$3"
    local details="$4"
    
    local sns_topic="arn:aws:sns:${AWS_REGION}:985869370256:bongaquino-${ENVIRONMENT}-discord-notifications"
    
    # Escape details JSON properly by using jq to create proper JSON structure
    local message=$(echo "$details" | jq -c --arg title "$title" --arg description "$description" --arg type "$alert_type" \
        '{title: $title, description: $description, type: $type, details: .}')

    aws sns publish \
        --region "$AWS_REGION" \
        --topic-arn "$sns_topic" \
        --message "$message" \
        --subject "$title" \
        >> "$LOG_FILE" 2>&1
}

# =============================================================================
# System Resource Monitoring
# =============================================================================

check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local cpu_num=${cpu_usage%.*}
    
    if [ "$cpu_num" -gt 0 ]; then
        log_message "CPU Usage: ${cpu_usage}%"
        
        send_metric "$SERVER_NAMESPACE" "ServerCPUUsage" "$cpu_num" "Percent" \
            '[{"Name":"Environment","Value":"'$ENVIRONMENT'"},{"Name":"Service","Value":"'$SERVICE'"}]'
        
        if [ "$cpu_num" -gt "$CPU_THRESHOLD" ]; then
            local details=$(cat <<EOF
{
    "CPU Usage": "${cpu_usage}%",
    "Threshold": "${CPU_THRESHOLD}%",
    "Server": "$SERVER_IP",
    "Status": "High CPU Usage"
}
EOF
)
            send_discord_alert "⚠️ High CPU Usage" \
                "Staging server CPU usage is at ${cpu_usage}%" \
                "warning" "$details"
        fi
    fi
}

check_memory() {
    local mem_info=$(free | grep '^Mem:')
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local available=$(echo $mem_info | awk '{print $7}')
    
    if [ "$total" -gt 0 ]; then
        local usage_percent=$((used * 100 / total))
        local used_gb=$((used / 1024 / 1024))
        local total_gb=$((total / 1024 / 1024))
        local available_gb=$((available / 1024 / 1024))
        
        log_message "Memory Usage: ${usage_percent}% (${used_gb}GB/${total_gb}GB, ${available_gb}GB available)"
        
        send_metric "$SERVER_NAMESPACE" "ServerMemoryUsage" "$usage_percent" "Percent" \
            '[{"Name":"Environment","Value":"'$ENVIRONMENT'"},{"Name":"Service","Value":"'$SERVICE'"}]'
        
        if [ "$usage_percent" -gt "$MEMORY_THRESHOLD" ]; then
            local details=$(cat <<EOF
{
    "Memory Usage": "${usage_percent}% (${used_gb}GB/${total_gb}GB)",
    "Available": "${available_gb}GB",
    "Threshold": "${MEMORY_THRESHOLD}%",
    "Server": "$SERVER_IP",
    "Status": "Critical Memory Usage"
}
EOF
)
            send_discord_alert "🚨 Critical Memory Usage" \
                "Staging server memory usage is critically high at ${usage_percent}%" \
                "error" "$details"
        fi
    fi
}

check_disk() {
    local disk_info=$(df / | tail -1)
    local usage_str=$(echo $disk_info | awk '{print $5}')
    local available=$(echo $disk_info | awk '{print $4}')
    local disk_usage=${usage_str%\%}
    
    if [ "$disk_usage" -gt 0 ]; then
        log_message "Disk Usage: ${disk_usage}% (${available} available)"
        
        send_metric "$SERVER_NAMESPACE" "ServerDiskUsage" "$disk_usage" "Percent" \
            '[{"Name":"Environment","Value":"'$ENVIRONMENT'"},{"Name":"Service","Value":"'$SERVICE'"}]'
        
        if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
            local details=$(cat <<EOF
{
    "Disk Usage": "${disk_usage}%",
    "Available": "${available}",
    "Threshold": "${DISK_THRESHOLD}%",
    "Server": "$SERVER_IP",
    "Status": "Critical Disk Space"
}
EOF
)
            send_discord_alert "🚨 Critical Disk Space" \
                "Staging server disk usage is critically high at ${disk_usage}%" \
                "error" "$details"
        fi
    fi
}

# =============================================================================
# Core Service Monitoring 
# =============================================================================

check_backend_api() {
    local start_time=$(date +%s%3N)
    local response=$(timeout 10 curl -s -w "%{http_code}" localhost:3000/ 2>/dev/null || echo "TIMEOUT000")
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    local http_code="${response: -3}"
    local body="${response%???}"
    
    log_message "Backend API: ${http_code} in ${response_time}ms"
    
    send_metric "$APP_NAMESPACE" "ApiResponseTime" "$response_time" "Milliseconds" \
        '[{"Name":"Environment","Value":"'$ENVIRONMENT'"},{"Name":"Service","Value":"'$SERVICE'"},{"Name":"Endpoint","Value":"/"}]'
    
    local previous_state=$(get_previous_state "backend_api")
    local current_state="healthy"
    
    # Check if API is healthy (200 status and reasonable response time)
    if [[ "$http_code" == "200" && "$response_time" -lt "$API_RESPONSE_THRESHOLD" ]]; then
        log_message "Backend API: Healthy"
        current_state="healthy"
        
        if [[ "$previous_state" == "down" ]]; then
            local recovery_details=$(cat <<EOF
{
    "Endpoint": "localhost:3000/",
    "Response Time": "${response_time}ms",
    "HTTP Status": "$http_code",
    "Previous Status": "Down",
    "Current Status": "Healthy",
    "Server": "$SERVER_IP",
    "Recovery Time": "$(date '+%Y-%m-%d %H:%M:%S UTC')"
}
EOF
)
            send_discord_alert "✅ Backend API Recovered" \
                "bongaquino backend API is now responding normally" \
                "success" "$recovery_details"
        fi
    else
        current_state="down"
        local details=$(cat <<EOF
{
    "Endpoint": "localhost:3000/",
    "Response Time": "${response_time}ms",
    "HTTP Status": "$http_code",
    "Response Body": "$body",
    "Server": "$SERVER_IP",
    "Status": "Failed"
}
EOF
)
        send_discord_alert "🚨 Backend API Down" \
            "bongaquino backend API is not responding properly" \
            "error" "$details"
    fi
    
    set_current_state "backend_api" "$current_state"
}

check_mongodb() {
    local start_time=$(date +%s%3N)
    local response=$(timeout 10 docker exec mongo mongosh --quiet --eval "db.runCommand({ping: 1}).ok" 2>/dev/null || echo "TIMEOUT")
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    log_message "MongoDB: Response time ${response_time}ms"
    
    send_metric "$APP_NAMESPACE" "MongoDBResponseTime" "$response_time" "Milliseconds" \
        '[{"Name":"Environment","Value":"'$ENVIRONMENT'"},{"Name":"Service","Value":"mongodb"},{"Name":"Operation","Value":"ping"}]'
    
    local previous_state=$(get_previous_state "mongodb")
    local current_state="healthy"
    
    if [[ "$response" == "1" ]]; then
        log_message "MongoDB: Healthy"
        current_state="healthy"
        
        if [[ "$previous_state" == "down" ]]; then
            local recovery_details=$(cat <<EOF
{
    "Database": "MongoDB",
    "Response Time": "${response_time}ms",
    "Previous Status": "Down",
    "Current Status": "Healthy",
    "Server": "$SERVER_IP",
    "Recovery Time": "$(date '+%Y-%m-%d %H:%M:%S UTC')"
}
EOF
)
            send_discord_alert "✅ MongoDB Recovered" \
                "MongoDB database is now responding normally" \
                "success" "$recovery_details"
        fi
    else
        current_state="down"
        local details=$(cat <<EOF
{
    "Database": "MongoDB",
    "Response Time": "${response_time}ms",
    "Response": "$response",
    "Server": "$SERVER_IP",
    "Status": "Failed"
}
EOF
)
        send_discord_alert "🚨 MongoDB Down" \
            "MongoDB database is not responding properly" \
            "error" "$details"
    fi
    
    set_current_state "mongodb" "$current_state"
}

check_redis() {
    local start_time=$(date +%s%3N)
    local response=$(timeout 10 docker exec redis redis-cli ping 2>/dev/null || echo "TIMEOUT")
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    log_message "Redis: Response time ${response_time}ms"
    
    send_metric "$APP_NAMESPACE" "RedisResponseTime" "$response_time" "Milliseconds" \
        '[{"Name":"Environment","Value":"'$ENVIRONMENT'"},{"Name":"Service","Value":"redis"},{"Name":"Operation","Value":"ping"}]'
    
    local previous_state=$(get_previous_state "redis")
    local current_state="healthy"
    
    if [[ "$response" == "PONG" ]]; then
        log_message "Redis: Healthy"
        current_state="healthy"
        
        if [[ "$previous_state" == "down" ]]; then
            local recovery_details=$(cat <<EOF
{
    "Database": "Redis",
    "Response Time": "${response_time}ms",
    "Previous Status": "Down", 
    "Current Status": "Healthy",
    "Server": "$SERVER_IP",
    "Recovery Time": "$(date '+%Y-%m-%d %H:%M:%S UTC')"
}
EOF
)
            send_discord_alert "✅ Redis Recovered" \
                "Redis cache is now responding normally" \
                "success" "$recovery_details"
        fi
    else
        current_state="down"
        local details=$(cat <<EOF
{
    "Database": "Redis",
    "Response Time": "${response_time}ms",
    "Response": "$response",
    "Server": "$SERVER_IP",
    "Status": "Failed"
}
EOF
)
        send_discord_alert "🚨 Redis Down" \
            "Redis cache is not responding properly" \
            "error" "$details"
    fi
    
    set_current_state "redis" "$current_state"
}

# =============================================================================
# Health Summary & Test Functions
# =============================================================================

send_health_summary() {
    local uptime_info=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local memory_info=$(free -h | grep '^Mem:' | awk '{print $3"/"$2}')
    local disk_info=$(df -h / | tail -1 | awk '{print $5}')
    
    # Get service health status
    local backend_status=$(get_previous_state "backend_api")
    local mongodb_status=$(get_previous_state "mongodb")
    local redis_status=$(get_previous_state "redis")
    
    local details=$(cat <<EOF
{
    "Server": "bongaquino-staging-backend ($SERVER_IP)",
    "Uptime": "$uptime_info",
    "Memory": "$memory_info",
    "Disk Usage": "$disk_info",
    "Staging Endpoints": {
        "Frontend": "https://app-staging.bongaquino.co.kr",
        "Backend API": "https://staging.bongaquino.co.kr",
        "MongoDB Admin": "mongo-express container"
    },
    "Core Services": {
        "Backend API": "${backend_status:-unknown}",
        "MongoDB": "${mongodb_status:-unknown}",
        "Redis": "${redis_status:-unknown}"
    },
    "Monitoring": "Baseline (Core Services Only)",
    "Last Check": "$(date '+%Y-%m-%d %H:%M:%S UTC')"
}
EOF
)
    
    send_discord_alert "INFO: Staging Backend Health Summary" \
        "Comprehensive health report for staging backend server" \
        "info" "$details"
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    case "${1:-check}" in
        "check")
            log_message "=== Starting baseline health checks ==="
            check_cpu
            check_memory
            check_disk
            check_backend_api
            check_mongodb
            check_redis
            log_message "=== Baseline health checks completed ==="
            ;;
        "summary")
            send_health_summary
            ;;
        "test")
            send_discord_alert "🧪 Test Alert" \
                "Testing staging server baseline monitoring" \
                "info" '{"Test": "Successful", "Server": "'$SERVER_IP'", "Scope": "Core Services Only"}'
            ;;
        "setup")
            log_message "Setting up baseline monitoring..."
            
            # Create log file
            sudo touch "$LOG_FILE" 2>/dev/null || true
            sudo chown ubuntu:ubuntu "$LOG_FILE" 2>/dev/null || true
            
            # Add to crontab (every 5 minutes for core services)
            (crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/monitoring/staging-baseline-monitor.sh check") | crontab -
            (crontab -l 2>/dev/null; echo "0 8 * * * /home/ubuntu/monitoring/staging-baseline-monitor.sh summary") | crontab -
            
            log_message "Baseline monitoring setup complete!"
            send_discord_alert "🚀 Baseline Monitoring Started" \
                "Server-side baseline monitoring has been activated" \
                "success" '{"Server": "'$SERVER_IP'", "Status": "Active", "Scope": "Core Services Only"}'
            ;;
        *)
            echo "Usage: $0 {check|summary|test|setup}"
            echo "  check   - Run health checks (default)"
            echo "  summary - Send daily health summary"
            echo "  test    - Send test alert"
            echo "  setup   - Setup monitoring with cron jobs"
            exit 1
            ;;
    esac
}

# Ensure AWS CLI is available and configured
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Run main function
main "$@" 