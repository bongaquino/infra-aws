#!/bin/bash

# Unified IPFS Health Summary Script
# Sends event-driven alerts on state changes AND daily summary reports

set -euo pipefail

# Discord Webhook (same as existing)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
DISCORD_USERNAME="🟦 IPFS All-Peers Monitor"
DISCORD_AVATAR_URL="https://ipfs.io/ipfs/QmYjtig7VJQ6XsnUjqqJvj7QaMcCAwtrgNdahSiFofrE7o"

USER="ipfs"
STATE_DIR="/tmp/ipfs-cluster-states"

# Create state directory
mkdir -p "$STATE_DIR"

# Check if this is a daily summary run
DAILY_SUMMARY="${1:-false}"

get_health_summary() {
  local name="$1"
  local ip="$2"
  local script_name=""
  case "$name" in
    "Bootstrap") script_name="ipfs-bootstrap-monitor.sh" ;;
    "Peer-01") script_name="ipfs-peer-01-monitor.sh" ;;
    "Peer-02") script_name="ipfs-peer-02-monitor.sh" ;;
  esac
  
  # Get short summary - just final status counts
  local output=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$USER@$ip" \
    "if [ -x ~/$script_name ]; then ~/$script_name 2>/dev/null | tail -1; else echo 'No script found'; fi" 2>/dev/null || echo "SSH failed")
  
  # Extract status from output like "=== Health checks completed: 5/5 passed ==="
  if echo "$output" | grep -q "Health checks completed:"; then
    local status=$(echo "$output" | grep -o "[0-9]/[0-9] passed")
    if echo "$output" | grep -q "5/5 passed"; then
      echo "HEALTHY"
    else
      echo "ISSUES"
    fi
  else
    echo "UNREACHABLE"
  fi
}

get_previous_state() {
  local node="$1"
  local state_file="$STATE_DIR/${node}_state"
  [ -f "$state_file" ] && cat "$state_file" || echo "UNKNOWN"
}

set_current_state() {
  local node="$1"
  local state="$2"
  local state_file="$STATE_DIR/${node}_state"
  echo "$state" > "$state_file"
}

send_discord_notification() {
  local title="$1"
  local description="$2"
  local color="$3"
  local fields="$4"
  
  cat > /tmp/ipfs_alert_payload.json << EOF
{
  "username": "$DISCORD_USERNAME",
  "avatar_url": "$DISCORD_AVATAR_URL",
  "embeds": [
    {
      "title": "$title",
      "description": "$description",
      "color": $color,
      "fields": $fields,
      "footer": { "text": "IPFS Cluster Alert" },
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }
  ]
}
EOF

  curl -s -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d @/tmp/ipfs_alert_payload.json
}

# Check all nodes (excluding Peer-03)
echo "Checking IPFS nodes..."

BOOTSTRAP_STATUS="$(get_health_summary "Bootstrap" "10.0.0.17")"
PEER01_STATUS="$(get_health_summary "Peer-01" "<PEER_01_IP>")"
PEER02_STATUS="$(get_health_summary "Peer-02" "<PEER_02_IP>")"

# Get previous states
BOOTSTRAP_PREV="$(get_previous_state "Bootstrap")"
PEER01_PREV="$(get_previous_state "Peer-01")"
PEER02_PREV="$(get_previous_state "Peer-02")"

# Track state changes
CHANGES=""
PROBLEMS=""
RECOVERIES=""

check_state_change() {
  local node="$1"
  local prev="$2" 
  local current="$3"
  local ip="$4"
  local storage="$5"
  
  if [ "$prev" != "$current" ]; then
    if [ "$current" = "HEALTHY" ]; then
      RECOVERIES="${RECOVERIES}{\"name\": \"✅ $node RECOVERED\", \"value\": \"**$node** ($ip)\\n🔄 $prev → $current\\n$storage\", \"inline\": true},"
    else
      PROBLEMS="${PROBLEMS}{\"name\": \"❌ $node PROBLEM\", \"value\": \"**$node** ($ip)\\n🚨 $prev → $current\\n$storage\", \"inline\": true},"
    fi
    CHANGES="true"
  fi
  
  # Update state
  set_current_state "$node" "$current"
}

# Check each node for state changes (excluding Peer-03)
check_state_change "Bootstrap" "$BOOTSTRAP_PREV" "$BOOTSTRAP_STATUS" "10.0.0.17" "3 cluster peers"
check_state_change "Peer-01" "$PEER01_PREV" "$PEER01_STATUS" "<PEER_01_IP>" "14.6TB expandable"
check_state_change "Peer-02" "$PEER02_PREV" "$PEER02_STATUS" "<PEER_02_IP>" "125TB RAID-6"

# Send notification only if there are changes OR if it's daily summary time
if [ "$CHANGES" = "true" ]; then
  # Combine problems and recoveries
  ALL_FIELDS="${PROBLEMS}${RECOVERIES}"
  ALL_FIELDS="${ALL_FIELDS%,}"  # Remove trailing comma
  
  if [ -n "$PROBLEMS" ] && [ -n "$RECOVERIES" ]; then
    TITLE="🔄 IPFS Cluster Status Changes"
    DESC="Problems and recoveries detected"
    COLOR=16776960  # Orange
  elif [ -n "$PROBLEMS" ]; then
    TITLE="🚨 IPFS Cluster Problems Detected"
    DESC="One or more nodes experiencing issues"
    COLOR=15158332  # Red
  else
    TITLE="✅ IPFS Cluster Services Recovered"
    DESC="All issues have been resolved"
    COLOR=65280     # Green
  fi
  
  send_discord_notification "$TITLE" "$DESC" "$COLOR" "[$ALL_FIELDS]"
  echo "State changes detected - Discord notification sent."
elif [ "$DAILY_SUMMARY" = "true" ]; then
  # Send daily summary regardless of state changes (excluding Peer-03)
  SUMMARY_FIELDS=""
  SUMMARY_FIELDS="${SUMMARY_FIELDS}{\"name\": \"Bootstrap Node\", \"value\": \"**Bootstrap** (10.0.0.17)\\n✅ $BOOTSTRAP_STATUS\\n3 cluster peers\", \"inline\": true},"
  SUMMARY_FIELDS="${SUMMARY_FIELDS}{\"name\": \"Peer-01\", \"value\": \"**Peer-01** (<PEER_01_IP>)\\n✅ $PEER01_STATUS\\n14.6TB expandable\", \"inline\": true},"
  SUMMARY_FIELDS="${SUMMARY_FIELDS}{\"name\": \"Peer-02\", \"value\": \"**Peer-02** (<PEER_02_IP>)\\n✅ $PEER02_STATUS\\n125TB RAID-6\", \"inline\": true}"
  
  send_discord_notification "📊 Daily IPFS Health Summary" "Daily Health Report for IPFS - $(date '+%Y-%m-%d')" "3447003" "[$SUMMARY_FIELDS]"
  echo "Daily health summary sent."
else
  echo "No state changes detected - no notification sent."
fi

echo "IPFS cluster monitoring completed." 