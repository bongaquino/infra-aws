#!/bin/bash

# Configuration
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1253567522705961032/LGU8x_LfOqQgJaFoRaVHC6q70YF9PiL0_P3L5iXCn9IrhPvS6_qKmkbshWAJOKZpGLQ6"
CONTAINERS=("server" "redis" "mongo-express" "mongo" "redis-commander" "nginx-proxy")
HOSTNAME="staging.bongaquino.co.kr"

# Discord Colors (Standardized)
COLOR_GREEN=65280      # Green (FIXED - was 3066993)
COLOR_RED=15158332     # Red (correct)
COLOR_YELLOW=16776960  # Orange (correct) 
COLOR_BLUE=3447003     # Blue (standardized)

# Previous states file
PREV_STATES_FILE="/tmp/previous_states"

# Function to get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S KST'
}

# Function to get container status
get_container_status() {
    local container=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        echo "Running"
    else
        echo "Down"
    fi
}

# Function to get container resource usage
get_container_resources() {
    local container=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        local stats=$(docker stats $container --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" | tail -n 1)
        local cpu=$(echo $stats | awk '{print $1}')
        local memory=$(echo $stats | awk '{print $2}')
        echo "${cpu} CPU, ${memory} Memory"
    else
        echo "N/A"
    fi
}

# Function to get container uptime
get_container_uptime() {
    local container=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
        local uptime=$(docker ps --format "table {{.Names}}\t{{.RunningFor}}" | grep "^${container}" | awk '{$1=""; print $0}' | sed 's/^ *//')
        echo "$uptime"
    else
        echo "N/A"
    fi
}

# Function to get system resource usage
get_system_resources() {
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    
    # Memory usage
    local mem_info=$(free | grep Mem)
    local total_mem=$(echo $mem_info | awk '{print $2}')
    local used_mem=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$(echo "scale=1; $used_mem * 100 / $total_mem" | bc)
    
    # Disk usage
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "CPU: ${cpu_usage}%, Memory: ${mem_usage}%, Disk: ${disk_usage}%"
}

# Function to check MongoDB connection
check_mongodb() {
    local status="Down"
    local response_time="N/A"
    
    if docker ps --format "table {{.Names}}" | grep -q "^mongo$"; then
        local start_time=$(date +%s%3N)
        if docker exec mongo mongosh --eval "db.runCommand('ping')" &>/dev/null; then
            status="Connected"
            local end_time=$(date +%s%3N)
            response_time="$((end_time - start_time))ms"
        else
            status="Connection Failed"
        fi
    fi
    
    echo "$status|$response_time"
}

# Function to check Redis connection
check_redis() {
    local status="Down"
    local response_time="N/A"
    
    if docker ps --format "table {{.Names}}" | grep -q "^redis$"; then
        local start_time=$(date +%s%3N)
        if docker exec redis redis-cli ping | grep -q "PONG"; then
            status="Connected"
            local end_time=$(date +%s%3N)
            response_time="$((end_time - start_time))ms"
        else
            status="Connection Failed"
        fi
    fi
    
    echo "$status|$response_time"
}

# Function to check external backend API
check_external_backend() {
    local start_time=$(date +%s%3N)
    local response=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" "https://staging.bongaquino.co.kr" 2>/dev/null || echo "TIMEOUT")
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    local status="Down"
    if [ "$response" = "200" ]; then
        status="Up"
    elif [ "$response" = "TIMEOUT" ]; then
        status="Timeout"
        response_time="10000+"
    else
        status="Error ($response)"
    fi
    
    echo "$status|${response_time}ms"
}

# Function to send alert to Discord
send_alert() {
    local title="$1"
    local description="$2"
    local color="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    local payload=$(cat <<EOF
{
    "embeds": [{
        "title": "$title",
        "description": "$description",
        "color": $color,
        "timestamp": "$timestamp",
        "footer": {
            "text": "Staging Server Monitor"
        },
        "fields": [
            {
                "name": "Server",
                "value": "$HOSTNAME",
                "inline": true
            },
            {
                "name": "Time",
                "value": "$(get_timestamp)",
                "inline": true
            }
        ]
    }]
}
EOF
    )
    
    curl -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK" &>/dev/null
}

# Function to send recovery alert
send_recovery_alert() {
    local service="$1"
    local description="$2"
    
    send_alert "🟢 Service Recovered: $service" "$description" $COLOR_GREEN
}

# Function to load previous states
load_previous_states() {
    if [ -f "$PREV_STATES_FILE" ]; then
        source "$PREV_STATES_FILE"
    fi
}

# Function to save current states
save_current_states() {
    cat > "$PREV_STATES_FILE" << EOF
# Previous container states
EOF
    
    for container in "${CONTAINERS[@]}"; do
        local status=$(get_container_status "$container")
        local var_name=$(echo "${container^^}" | sed 's/-/_/g')
        echo "PREV_${var_name}_STATUS=\"$status\"" >> "$PREV_STATES_FILE"
    done
    
    # Save database connection states
    local mongo_result=$(check_mongodb)
    local mongo_status=$(echo "$mongo_result" | cut -d'|' -f1)
    echo "PREV_MONGODB_STATUS=\"$mongo_status\"" >> "$PREV_STATES_FILE"
    
    local redis_result=$(check_redis)
    local redis_status=$(echo "$redis_result" | cut -d'|' -f1)
    echo "PREV_REDIS_STATUS=\"$redis_status\"" >> "$PREV_STATES_FILE"
    
    # Save external backend status
    local backend_result=$(check_external_backend)
    local backend_status=$(echo "$backend_result" | cut -d'|' -f1)
    echo "PREV_BACKEND_STATUS=\"$backend_status\"" >> "$PREV_STATES_FILE"
}

# Function to check for state changes and send alerts
check_state_changes() {
    load_previous_states
    
    # Check container state changes
    for container in "${CONTAINERS[@]}"; do
        local current_status=$(get_container_status "$container")
        local var_name=$(echo "${container^^}" | sed 's/-/_/g')
        local prev_var="PREV_${var_name}_STATUS"
        local prev_status="${!prev_var}"
        
        if [ -n "$prev_status" ] && [ "$prev_status" != "$current_status" ]; then
            if [ "$current_status" = "Running" ]; then
                send_recovery_alert "$container Container" "Container **$container** has been restored and is now running normally."
            else
                send_alert "🔴 Container Down: $container" "Container **$container** is no longer running. Previous state: $prev_status" $COLOR_RED
            fi
        fi
    done
    
    # Check MongoDB state changes
    local mongo_result=$(check_mongodb)
    local mongo_status=$(echo "$mongo_result" | cut -d'|' -f1)
    if [ -n "$PREV_MONGODB_STATUS" ] && [ "$PREV_MONGODB_STATUS" != "$mongo_status" ]; then
        if [ "$mongo_status" = "Connected" ]; then
            send_recovery_alert "MongoDB Database" "MongoDB connection has been restored and is responding normally."
        else
            send_alert "🔴 Database Connection Failed: MongoDB" "MongoDB connection is failing. Current status: $mongo_status" $COLOR_RED
        fi
    fi
    
    # Check Redis state changes
    local redis_result=$(check_redis)
    local redis_status=$(echo "$redis_result" | cut -d'|' -f1)
    if [ -n "$PREV_REDIS_STATUS" ] && [ "$PREV_REDIS_STATUS" != "$redis_status" ]; then
        if [ "$redis_status" = "Connected" ]; then
            send_recovery_alert "Redis Cache" "Redis connection has been restored and is responding normally."
        else
            send_alert "🔴 Cache Connection Failed: Redis" "Redis connection is failing. Current status: $redis_status" $COLOR_RED
        fi
    fi
    
    # Check external backend state changes
    local backend_result=$(check_external_backend)
    local backend_status=$(echo "$backend_result" | cut -d'|' -f1)
    if [ -n "$PREV_BACKEND_STATUS" ] && [ "$PREV_BACKEND_STATUS" != "$backend_status" ]; then
        if [ "$backend_status" = "Up" ]; then
            send_recovery_alert "External Backend API" "External backend API has been restored and is responding normally."
        else
            send_alert "🔴 External Backend API Down" "External backend API is not responding properly. Status: $backend_status" $COLOR_RED
        fi
    fi
}

# Function to generate and send status report
send_status_report() {
    local report_type="$1"  # "health_check" or "daily_summary"
    local timestamp=$(get_timestamp)
    local system_resources=$(get_system_resources)
    
    # Container status checks
    local container_status=""
    local all_containers_running=true
    
    for container in "${CONTAINERS[@]}"; do
        local status=$(get_container_status "$container")
        local resources=$(get_container_resources "$container")
        local uptime=$(get_container_uptime "$container")
        
        if [ "$status" = "Running" ]; then
            container_status+=":white_check_mark: **$container**: $status\n"
            container_status+="  - Resources: $resources\n"
            container_status+="  - Uptime: $uptime\n"
        else
            container_status+=":x: **$container**: $status\n"
            all_containers_running=false
        fi
        container_status+="\n"
    done
    
    # Database connections
    local mongo_result=$(check_mongodb)
    local mongo_status=$(echo "$mongo_result" | cut -d'|' -f1)
    local mongo_time=$(echo "$mongo_result" | cut -d'|' -f2)
    
    local redis_result=$(check_redis)
    local redis_status=$(echo "$redis_result" | cut -d'|' -f1)
    local redis_time=$(echo "$redis_result" | cut -d'|' -f2)
    
    # External backend API
    local backend_result=$(check_external_backend)
    local backend_status=$(echo "$backend_result" | cut -d'|' -f1)
    local backend_time=$(echo "$backend_result" | cut -d'|' -f2)
    
    # Determine overall health
    local overall_status="Healthy"
    local color=$COLOR_GREEN
    local icon=":white_check_mark:"
    
    if [ "$all_containers_running" = false ] || 
       [ "$mongo_status" != "Connected" ] || 
       [ "$redis_status" != "Connected" ] || 
       [ "$backend_status" != "Up" ]; then
        overall_status="Issues Detected"
        color=$COLOR_YELLOW
        icon=":warning:"
    fi
    
    # Create title based on report type
    local title=""
    if [ "$report_type" = "daily_summary" ]; then
        title="$icon Daily Health Summary - $overall_status"
    else
        title="$icon Health Check Report - $overall_status"
    fi
    
    # Prepare the description
    local description="**System Overview**\n"
    description+="System Resources: $system_resources\n\n"
    description+="**Container Status**\n$container_status"
    description+="**Database Connections**\n"
    
    if [ "$mongo_status" = "Connected" ]; then
        description+=":white_check_mark: **MongoDB**: $mongo_status ($mongo_time)\n"
    else
        description+=":x: **MongoDB**: $mongo_status\n"
    fi
    
    if [ "$redis_status" = "Connected" ]; then
        description+=":white_check_mark: **Redis**: $redis_status ($redis_time)\n"
    else
        description+=":x: **Redis**: $redis_status\n"
    fi
    
    description+="\n**External Services**\n"
    if [ "$backend_status" = "Up" ]; then
        description+=":white_check_mark: **Backend API**: $backend_status ($backend_time)\n"
    else
        description+=":x: **Backend API**: $backend_status\n"
    fi
    
    # Send the report
    local payload=$(cat <<EOF
{
    "embeds": [{
        "title": "$title",
        "description": "$description",
        "color": $color,
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
        "footer": {
            "text": "Staging Server Monitor • Generated at $timestamp"
        },
        "fields": [
            {
                "name": "Server",
                "value": "$HOSTNAME",
                "inline": true
            },
            {
                "name": "Report Type", 
                "value": "$(echo $report_type | sed 's/_/ /g' | sed 's/\b\w/\U&/g')",
                "inline": true
            }
        ]
    }]
}
EOF
    )
    
    curl -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK" &>/dev/null
}

# Function to generate detailed performance report
send_performance_report() {
    local timestamp=$(get_timestamp)
    local system_resources=$(get_system_resources)
    
    # Get detailed container performance
    local performance_data=""
    for container in "${CONTAINERS[@]}"; do
        local status=$(get_container_status "$container")
        if [ "$status" = "Running" ]; then
            local stats=$(docker stats $container --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | tail -n 1)
            local cpu=$(echo $stats | awk '{print $1}')
            local memory=$(echo $stats | awk '{print $2}')
            local network=$(echo $stats | awk '{print $3}')
            local disk_io=$(echo $stats | awk '{print $4}')
            
            performance_data+="**$container**\n"
            performance_data+="  CPU: $cpu | Memory: $memory\n"
            performance_data+="  Network I/O: $network\n"
            performance_data+="  Disk I/O: $disk_io\n\n"
        fi
    done
    
    # Database performance
    local mongo_result=$(check_mongodb)
    local mongo_status=$(echo "$mongo_result" | cut -d'|' -f1)
    local mongo_time=$(echo "$mongo_result" | cut -d'|' -f2)
    
    local redis_result=$(check_redis)
    local redis_status=$(echo "$redis_result" | cut -d'|' -f1)
    local redis_time=$(echo "$redis_result" | cut -d'|' -f2)
    
    # API performance
    local backend_result=$(check_external_backend)
    local backend_status=$(echo "$backend_result" | cut -d'|' -f1)
    local backend_time=$(echo "$backend_result" | cut -d'|' -f2)
    
    local description="**System Performance**\n"
    description+="$system_resources\n\n"
    description+="**Container Performance**\n$performance_data"
    description+="**Database Performance**\n"
    description+="MongoDB: $mongo_status ($mongo_time)\n"
    description+="Redis: $redis_status ($redis_time)\n\n"
    description+="**API Performance**\n"
    description+="Backend API: $backend_status ($backend_time)\n"
    
    local payload=$(cat <<EOF
{
    "embeds": [{
        "title": ":chart_with_upwards_trend: Performance Report",
        "description": "$description",
        "color": $COLOR_BLUE,
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
        "footer": {
            "text": "Staging Server Monitor • Performance Report • $timestamp"
        },
        "fields": [
            {
                "name": "Server",
                "value": "$HOSTNAME",
                "inline": true
            },
            {
                "name": "Active Containers",
                "value": "$(docker ps --format "table {{.Names}}" | wc -l | awk '{print $1-1}')",
                "inline": true
            }
        ]
    }]
}
EOF
    )
    
    curl -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK" &>/dev/null
}

# Main execution
main() {
    case "${1:-health_check}" in
        "health_check")
            check_state_changes
            save_current_states
            send_status_report "health_check"
            ;;
        "daily_summary")
            send_status_report "daily_summary"
            save_current_states
            ;;
        "performance")
            send_performance_report
            ;;
        "force_alert")
            # Force send alerts for testing
            send_alert "🔴 Test Alert" "This is a test alert to verify Discord integration is working." $COLOR_RED
            ;;
        "recovery_test")
            # Test recovery alerts
            send_recovery_alert "Test Service" "This is a test recovery alert."
            ;;
        *)
            echo "Usage: $0 [health_check|daily_summary|performance|force_alert|recovery_test]"
            echo "  health_check   - Check for state changes and send health report (default)"
            echo "  daily_summary  - Send comprehensive daily summary report"
            echo "  performance    - Send detailed performance report"
            echo "  force_alert    - Send test alert"
            echo "  recovery_test  - Send test recovery alert"
            exit 1
            ;;
    esac
}

main "$@" 