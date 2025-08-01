#!/bin/bash

# =============================================================================
# IPFS Peer-02 Incident Response Automation
# Server: 218.38.136.34 (Peer-02)
# SSH User: ipfs
# Discord Channel: #koneksi-alerts (same as staging/UAT)
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Server Configuration
SERVER_IP="218.38.136.34"
SERVER_USER="ipfs"
SERVER_NAME="IPFS Peer-02"

# Discord Configuration (same as staging/UAT)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
DISCORD_USERNAME="🔗 IPFS Peer-02 Monitor"
DISCORD_AVATAR_URL="https://ipfs.io/ipfs/QmYjtig7VJQ6XsnUjqqJvj7QaMcCAwtrgNdahSiFofrE7o"

# Monitoring Configuration
LOG_FILE="/tmp/ipfs-peer-02-monitor.log"
STATE_DIR="/tmp/ipfs-peer-02-monitoring"
TIMEOUT=30
CHECK_INTERVAL=300  # 5 minutes
MAX_RETRIES=3

# IPFS Configuration
IPFS_SWARM_PORT=4001
IPFS_API_PORT=5001
IPFS_GATEWAY_PORT=8080
CLUSTER_API_PORT=9094
CLUSTER_PROXY_PORT=9095
CLUSTER_PROXY_ALT_PORT=9096

# Alert thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
RESPONSE_TIME_THRESHOLD=5000  # 5 seconds

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

get_service_state() {
    local service="$1"
    local state_file="$STATE_DIR/${service}_state"
    [ -f "$state_file" ] && cat "$state_file" || echo "unknown"
}

set_service_state() {
    local service="$1"
    local state="$2"
    local state_file="$STATE_DIR/${service}_state"
    echo "$state" > "$state_file"
}

get_unique_message_id() {
    # Generate a unique message ID based on timestamp and random number
    echo "$(date +%s)-$((RANDOM % 9000 + 1000))"
}

# =============================================================================
# Discord Notification Functions
# =============================================================================

send_discord_alert() {
    local title="$1"
    local description="$2"
    local color="$3"
    local details="$4"
    local message_id="${5:-$(get_unique_message_id)}"
    
    local webhook_payload=$(cat <<EOF
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
          "name": "Server",
          "value": "$SERVER_NAME ($SERVER_IP)",
          "inline": true
        },
        {
          "name": "Timestamp",
          "value": "$(date '+%Y-%m-%d %H:%M:%S UTC')",
          "inline": true
        },
        {
          "name": "Message ID",
          "value": "$message_id",
          "inline": true
        },
        {
          "name": "Details",
          "value": "$details",
          "inline": false
        }
      ],
      "footer": {
        "text": "IPFS Peer-02 Monitor"
      }
    }
  ]
}
EOF
)

    local response=$(curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$webhook_payload")
    
    if [ $? -eq 0 ]; then
        log_message "Discord alert sent successfully: $title (ID: $message_id)"
    else
        log_message "Failed to send Discord alert: $title"
    fi
}

send_critical_alert() {
    send_discord_alert "🚨 CRITICAL: $1" "$2" 15158332 "$3"  # Red
}

send_warning_alert() {
    send_discord_alert "⚠️ WARNING: $1" "$2" 16776960 "$3"  # Orange
}

send_info_alert() {
    send_discord_alert "ℹ️ INFO: $1" "$2" 3447003 "$3"  # Blue (standardized)
}

send_success_alert() {
    send_discord_alert "✅ RESOLVED: $1" "$2" 65280 "$3"  # Green
}

# =============================================================================
# Command Execution Functions
# =============================================================================

# Detect if we're running locally on the peer node
is_local_execution() {
    # Check multiple ways to detect if we're on the peer node
    local current_ip=""
    
    # Try Linux method first
    if command -v hostname >/dev/null 2>&1; then
        current_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    fi
    
    # Try macOS method if Linux method failed
    if [ -z "$current_ip" ] && command -v ifconfig >/dev/null 2>&1; then
        current_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1 || echo "")
    fi
    
    # Check if we match the server IP, hostname, or user
    [ "$current_ip" = "$SERVER_IP" ] || [ "$(hostname)" = "peer-02" ] || [ "$USER" = "$SERVER_USER" ]
}

# Execute command either locally or via SSH
execute_command() {
    local command="$1"
    
    if is_local_execution; then
        # Execute locally
        bash -c "$command"
    else
        # Execute via SSH
        local max_attempts=3
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$SERVER_USER@$SERVER_IP" "$command"; then
                return 0
            fi
            
            log_message "SSH attempt $attempt failed, retrying..."
            sleep 5
            attempt=$((attempt + 1))
        done
        
        return 1
    fi
}

# SSH execution wrapper
ssh_execute() {
    local command="$1"
    execute_command "$command"
}

# =============================================================================
# SSH Connectivity Test
# =============================================================================

test_ssh_connectivity() {
    log_message "Testing SSH connectivity to $SERVER_IP..."
    
    if is_local_execution; then
        log_message "Running locally on Peer-02"
        return 0
    fi
    
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$SERVER_USER@$SERVER_IP" "echo 'SSH connection successful'"; then
        log_message "SSH connectivity: OK"
        return 0
    else
        log_message "SSH connectivity: FAILED"
        return 1
    fi
}

# =============================================================================
# Health Check Functions
# =============================================================================

check_system_resources() {
    log_message "Checking system resources..."
    
    local previous_state=$(get_service_state "system_resources")
    
    # CPU Usage
    local cpu_usage=$(ssh_execute "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | sed 's/%us,//' | cut -d'.' -f1" 2>/dev/null)
    if [ -z "$cpu_usage" ] || [ "$cpu_usage" = "" ]; then
        cpu_usage="unknown"
    fi
    
    # Memory Usage
    local memory_info=$(ssh_execute "free | grep Mem" 2>/dev/null)
    local memory_usage="unknown"
    if [ -n "$memory_info" ]; then
        local total_mem=$(echo "$memory_info" | awk '{print $2}')
        local used_mem=$(echo "$memory_info" | awk '{print $3}')
        if [ "$total_mem" -gt 0 ]; then
            memory_usage=$((used_mem * 100 / total_mem))
        fi
    fi
    
    # Disk Usage
    local disk_usage=$(ssh_execute "df -h /data | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null)
    if [ -z "$disk_usage" ]; then
        disk_usage="unknown"
    fi
    
    # Check thresholds
    local alerts=""
    local status="healthy"
    
    if [ "$cpu_usage" != "unknown" ] && [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        alerts="${alerts}CPU usage: ${cpu_usage}% (>${CPU_THRESHOLD}%) "
        status="critical"
    fi
    
    if [ "$memory_usage" != "unknown" ] && [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        alerts="${alerts}Memory usage: ${memory_usage}% (>${MEMORY_THRESHOLD}%) "
        status="critical"
    fi
    
    if [ "$disk_usage" != "unknown" ] && [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        alerts="${alerts}Disk usage: ${disk_usage}% (>${DISK_THRESHOLD}%) "
        status="critical"
    fi
    
    local details="CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}% (125TB RAID-6)"
    
    if [ "$status" = "critical" ]; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "System Resources Critical" "Resource usage exceeded thresholds" "$details - $alerts"
        fi
        set_service_state "system_resources" "critical"
        log_message "System resources: CRITICAL - $details"
        return 1
    else
        if [ "$previous_state" = "critical" ]; then
            send_success_alert "System Resources Recovered" "Resource usage back to normal" "$details"
        fi
        set_service_state "system_resources" "healthy"
        log_message "System resources: OK - $details"
        return 0
    fi
}

check_ipfs_daemon() {
    log_message "Checking IPFS daemon..."
    
    local previous_state=$(get_service_state "ipfs_daemon")
    
    # Check if IPFS container is running
    local container_status=$(ssh_execute "docker ps --filter name=ipfs --format '{{.Status}}'" 2>/dev/null)
    if [ -z "$container_status" ]; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS Daemon Down" "IPFS container is not running" "Container status: Not found"
        fi
        set_service_state "ipfs_daemon" "critical"
        log_message "IPFS daemon: CRITICAL - Container not running"
        return 1
    fi
    
    # Check IPFS API responsiveness
    local api_response=$(ssh_execute "curl -s -m 5 -X POST http://localhost:$IPFS_API_PORT/api/v0/version" 2>/dev/null)
    if [ -z "$api_response" ] || ! echo "$api_response" | grep -q "Version"; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS API Unresponsive" "IPFS API not responding" "API endpoint: http://localhost:$IPFS_API_PORT/api/v0/version"
        fi
        set_service_state "ipfs_daemon" "critical"
        log_message "IPFS daemon: CRITICAL - API unresponsive"
        return 1
    fi
    
    # Check IPFS ID
    local ipfs_id=$(ssh_execute "docker exec ipfs ipfs id -f='<id>'" 2>/dev/null)
    if [ -z "$ipfs_id" ]; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS ID Failed" "Cannot retrieve IPFS node ID" "IPFS ID command failed"
        fi
        set_service_state "ipfs_daemon" "critical"
        log_message "IPFS daemon: CRITICAL - Cannot retrieve ID"
        return 1
    fi
    
    local details="Container: $container_status, API: Responsive, ID: ${ipfs_id:0:12}..."
    
    if [ "$previous_state" = "critical" ]; then
        send_success_alert "IPFS Daemon Recovered" "IPFS daemon is now healthy" "$details"
    fi
    
    set_service_state "ipfs_daemon" "healthy"
    log_message "IPFS daemon: OK - $details"
    return 0
}

check_ipfs_cluster() {
    log_message "Checking IPFS cluster..."
    
    local previous_state=$(get_service_state "ipfs_cluster")
    
    # Check if IPFS cluster container is running
    local cluster_container_status=$(ssh_execute "docker ps --filter name=ipfs-cluster --format '{{.Status}}'" 2>/dev/null)
    if [ -z "$cluster_container_status" ]; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS Cluster Down" "IPFS cluster container is not running" "Container status: Not found"
        fi
        set_service_state "ipfs_cluster" "critical"
        log_message "IPFS cluster: CRITICAL - Container not running"
        return 1
    fi
    
    # Check cluster API responsiveness
    local cluster_response=$(ssh_execute "curl -s -m 5 http://localhost:$CLUSTER_API_PORT/id" 2>/dev/null)
    if [ -z "$cluster_response" ] || ! echo "$cluster_response" | grep -q "version"; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "IPFS Cluster API Unresponsive" "IPFS cluster API not responding" "API endpoint: http://localhost:$CLUSTER_API_PORT/id"
        fi
        set_service_state "ipfs_cluster" "critical"
        log_message "IPFS cluster: CRITICAL - API unresponsive"
        return 1
    fi
    
    # Check cluster peers (for private isolated cluster, expect minimal peers)
    local cluster_peers=$(ssh_execute "docker exec ipfs-cluster ipfs-cluster-ctl peers ls" 2>/dev/null)
    local peer_count="0"
    if [ -n "$cluster_peers" ]; then
        peer_count=$(echo "$cluster_peers" | grep -c '^12D3' || echo "0")
    fi
    
    local details="Container: $cluster_container_status, API: Responsive, Peers: $peer_count (Private cluster)"
    
    if [ "$previous_state" = "critical" ]; then
        send_success_alert "IPFS Cluster Recovered" "IPFS cluster is now healthy" "$details"
    fi
    
    set_service_state "ipfs_cluster" "healthy"
    log_message "IPFS cluster: OK - $details"
    return 0
}

check_security_status() {
    log_message "Checking security status..."
    
    local previous_state=$(get_service_state "security_status")
    
    # Check for recent failed login attempts
    local failed_logins=$(ssh_execute "grep 'Failed password' /var/log/auth.log | tail -10 | wc -l" 2>/dev/null || echo "0")
    
    # Check UFW status
    local ufw_status=$(ssh_execute "sudo ufw status | head -1" 2>/dev/null || echo "unknown")
    
    # Check fail2ban status
    local fail2ban_status=$(ssh_execute "systemctl is-active fail2ban" 2>/dev/null || echo "inactive")
    
    local alerts=""
    local status="healthy"
    
    if [ "$failed_logins" -gt 5 ]; then
        alerts="${alerts}High failed login attempts: $failed_logins "
        status="warning"
    fi
    
    if ! echo "$ufw_status" | grep -q "active"; then
        alerts="${alerts}UFW firewall not active "
        status="warning"
    fi
    
    if [ "$fail2ban_status" != "active" ]; then
        alerts="${alerts}Fail2ban not active "
        status="warning"
    fi
    
    local details="Failed logins: $failed_logins, UFW: $ufw_status, Fail2ban: $fail2ban_status"
    
    if [ "$status" = "warning" ]; then
        if [ "$previous_state" != "warning" ]; then
            send_warning_alert "Security Status Warning" "Security configuration needs attention" "$details - $alerts"
        fi
        set_service_state "security_status" "warning"
        log_message "Security status: WARNING - $details"
        return 1
    else
        if [ "$previous_state" = "warning" ]; then
            send_success_alert "Security Status Recovered" "Security configuration is healthy" "$details"
        fi
        set_service_state "security_status" "healthy"
        log_message "Security status: OK - $details"
        return 0
    fi
}

check_storage_health() {
    log_message "Checking storage health..."
    
    local previous_state=$(get_service_state "storage_health")
    
    # Check IPFS repo integrity
    local repo_check=$(ssh_execute "docker exec ipfs ipfs repo stat 2>/dev/null" 2>/dev/null || echo "failed")
    local repo_status="unknown"
    if echo "$repo_check" | grep -q "RepoSize"; then
        repo_status="healthy"
    else
        repo_status="failed"
    fi
    
    # Check data directory disk space
    local data_disk_usage=$(ssh_execute "df -h /data | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "unknown")
    
    # Check for storage errors in system logs
    local storage_errors=$(ssh_execute "dmesg | grep -i 'error\\|fail' | grep -i 'storage\\|disk\\|mount' | tail -5 | wc -l" 2>/dev/null || echo "0")
    
    local alerts=""
    local status="healthy"
    
    if [ "$repo_status" = "failed" ]; then
        alerts="${alerts}IPFS repo check failed "
        status="critical"
    fi
    
    if [ "$data_disk_usage" != "unknown" ] && [ "$data_disk_usage" -gt "$DISK_THRESHOLD" ]; then
        alerts="${alerts}Data disk usage: ${data_disk_usage}% "
        status="critical"
    fi
    
    if [ "$storage_errors" -gt 0 ]; then
        alerts="${alerts}Storage errors in logs: $storage_errors "
        status="warning"
    fi
    
    local details="IPFS repo: $repo_status, Data disk: ${data_disk_usage}%, Storage errors: $storage_errors (125TB RAID-6)"
    
    if [ "$status" = "critical" ]; then
        if [ "$previous_state" != "critical" ]; then
            send_critical_alert "Storage Health Critical" "Storage system has critical issues" "$details - $alerts"
        fi
        set_service_state "storage_health" "critical"
        log_message "Storage health: CRITICAL - $details"
        return 1
    elif [ "$status" = "warning" ]; then
        if [ "$previous_state" != "warning" ]; then
            send_warning_alert "Storage Health Warning" "Storage system needs attention" "$details - $alerts"
        fi
        set_service_state "storage_health" "warning"
        log_message "Storage health: WARNING - $details"
        return 1
    else
        if [ "$previous_state" = "critical" ] || [ "$previous_state" = "warning" ]; then
            send_success_alert "Storage Health Recovered" "Storage system is healthy" "$details"
        fi
        set_service_state "storage_health" "healthy"
        log_message "Storage health: OK - $details"
        return 0
    fi
}

# =============================================================================
# Main Health Check Runner
# =============================================================================

run_all_checks() {
    log_message "=== Starting IPFS Peer-02 health checks ==="
    
    local checks_passed=0
    local total_checks=0
    
    # Test SSH connectivity first
    if ! test_ssh_connectivity; then
        send_critical_alert "SSH Connectivity Failed" "Cannot connect to IPFS Peer-02" "Server: $SERVER_IP, User: $SERVER_USER"
        return 1
    fi
    
    # Run all health checks (network monitoring disabled for private isolated cluster)
    local checks=(
        "check_system_resources"
        "check_ipfs_daemon"
        "check_ipfs_cluster"
        "check_security_status"
        "check_storage_health"
    )
    
    for check in "${checks[@]}"; do
        total_checks=$((total_checks + 1))
        if $check; then
            checks_passed=$((checks_passed + 1))
        fi
    done
    
    log_message "=== Health checks completed: $checks_passed/$total_checks passed ==="
    
    if [ "$checks_passed" -eq "$total_checks" ]; then
        return 0
    else
        return 1
    fi
}

send_health_summary() {
    log_message "Sending health summary..."
    
    local summary_details=""
    
    # Gather current states (network monitoring disabled for private isolated cluster)
    local system_state=$(get_service_state "system_resources")
    local ipfs_state=$(get_service_state "ipfs_daemon")
    local cluster_state=$(get_service_state "ipfs_cluster")
    local security_state=$(get_service_state "security_status")
    local storage_state=$(get_service_state "storage_health")
    
    # Get system metrics
    local cpu_usage=$(ssh_execute "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | sed 's/%us,//'" 2>/dev/null || echo "unknown")
    local memory_info=$(ssh_execute "free | grep Mem" 2>/dev/null || echo "")
    local memory_usage="unknown"
    if [ -n "$memory_info" ]; then
        local total_mem=$(echo "$memory_info" | awk '{print $2}')
        local used_mem=$(echo "$memory_info" | awk '{print $3}')
        memory_usage=$((used_mem * 100 / total_mem))
    fi
    local disk_usage=$(ssh_execute "df -h /data | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "unknown")
    
    summary_details="**System Resources:** $system_state (CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}%)\n"
    summary_details="${summary_details}**IPFS Daemon:** $ipfs_state\n"
    summary_details="${summary_details}**IPFS Cluster:** $cluster_state (Private isolated cluster)\n"
    summary_details="${summary_details}**Security:** $security_state\n"
    summary_details="${summary_details}**Storage:** $storage_state (125TB RAID-6)"
    
    send_info_alert "IPFS Peer-02 Health Summary" "Daily health report" "$summary_details"
}

# =============================================================================
# Incident Response Functions
# =============================================================================

restart_ipfs_services() {
    log_message "Attempting to restart IPFS services..."
    
    send_info_alert "IPFS Service Restart" "Attempting automatic service restart" "Restarting IPFS daemon and cluster services"
    
    # Restart IPFS daemon
    if ssh_execute "cd /home/ipfs/koneksi-ipfs/docker-compose/koneksi-ipfs-kr-peer-02 && docker-compose restart ipfs"; then
        log_message "IPFS daemon restarted successfully"
    else
        log_message "Failed to restart IPFS daemon"
        send_critical_alert "IPFS Restart Failed" "Failed to restart IPFS daemon" "Manual intervention required"
        return 1
    fi
    
    # Wait for daemon to stabilize
    sleep 10
    
    # Restart cluster
    if ssh_execute "cd /home/ipfs/koneksi-ipfs/docker-compose/koneksi-ipfs-kr-peer-02 && docker-compose restart ipfs-cluster"; then
        log_message "IPFS cluster restarted successfully"
    else
        log_message "Failed to restart IPFS cluster"
        send_critical_alert "IPFS Cluster Restart Failed" "Failed to restart IPFS cluster" "Manual intervention required"
        return 1
    fi
    
    # Wait for services to stabilize
    sleep 30
    
    # Verify services are running
    if run_all_checks; then
        send_success_alert "IPFS Services Restarted" "Automatic restart completed successfully" "All services are now healthy"
        return 0
    else
        send_critical_alert "IPFS Restart Incomplete" "Services restarted but health checks still failing" "Manual intervention required"
        return 1
    fi
}

cleanup_storage() {
    log_message "Performing storage cleanup..."
    
    send_info_alert "Storage Cleanup" "Performing automatic storage cleanup" "Cleaning up temporary files and optimizing storage"
    
    # Clean up Docker
    if ssh_execute "docker system prune -f"; then
        log_message "Docker cleanup completed"
    else
        log_message "Docker cleanup failed"
    fi
    
    # IPFS garbage collection
    if ssh_execute "docker exec ipfs ipfs repo gc"; then
        log_message "IPFS garbage collection completed"
        send_success_alert "Storage Cleanup Completed" "Storage optimization finished" "IPFS repository cleaned and optimized"
    else
        log_message "IPFS garbage collection failed"
        send_warning_alert "Storage Cleanup Failed" "Failed to perform IPFS garbage collection" "Manual cleanup may be required"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    create_state_dir
    
    case "${1:-check}" in
        "check")
            log_message "=== Starting IPFS Peer-02 monitoring ==="
            run_all_checks
            ;;
        "summary")
            send_health_summary
            ;;
        "test")
            send_discord_alert "🧪 Test Alert" \
                "Testing IPFS Peer-02 monitoring integration" \
                3447003 \
                "Test: Successful, Server: $SERVER_IP, SSH User: $SERVER_USER"
            ;;
        "restart")
            restart_ipfs_services
            ;;
        "cleanup")
            cleanup_storage
            ;;
        "setup")
            log_message "Setting up IPFS Peer-02 monitoring..."
            
            # Create log file
            touch "$LOG_FILE"
            create_state_dir
            
            # Test connectivity
            if ! test_ssh_connectivity; then
                log_message "SSH connectivity test failed - please check connection"
                exit 1
            fi
            
            # Add to crontab
            (crontab -l 2>/dev/null | grep -v "ipfs-peer-02-monitor.sh"; echo "*/5 * * * * $(realpath $0) check") | crontab -
            (crontab -l 2>/dev/null | grep -v "ipfs-peer-02-monitor.sh"; echo "0 8 * * * $(realpath $0) summary") | crontab -
            
            log_message "IPFS Peer-02 monitoring setup complete!"
            send_success_alert "IPFS Peer-02 Monitoring Started" \
                "Automated monitoring has been activated" \
                "Server: $SERVER_IP, Check interval: 5 minutes, Daily summary: 8:00 AM"
            ;;
        *)
            echo "Usage: $0 {check|summary|test|restart|cleanup|setup}"
            echo "  check    - Run health checks (default)"
            echo "  summary  - Send daily health summary"
            echo "  test     - Send test alert"
            echo "  restart  - Restart IPFS services"
            echo "  cleanup  - Perform storage cleanup"
            echo "  setup    - Setup monitoring with cron jobs"
            exit 1
            ;;
    esac
}

# Ensure script is executable and run main function
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi 