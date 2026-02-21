#!/usr/bin/env bash
set -euo pipefail

risk="${1:-show}"

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
DAEMON_LOG="DOCS/RUNS/policy_engine_daemon.log"

log() {
  echo "$(date -Is) [policy-engine] $1" | tee -a "$DAEMON_LOG"
}

check_integrity() {
  if ! grep -q '"exec": "deny"' "$CONFIG_FILE" 2>/dev/null; then
    log "CRITICAL: Policy violation detected in $CONFIG_FILE. Resetting policy..."
    # Attempt to fix the file if possible, or at least alert
    sed -i 's/"exec": "allow"/"exec": "deny"/' "$CONFIG_FILE" || true
    return 1
  fi
  return 0
}

check_workspaces() {
  # Monitor for unauthorized wmctrl -t calls by checking if windows move or if wmctrl is called
  # A simple way is to check the current workspace periodically if we expect it to be fixed
  # Or monitor the process list for wmctrl -t
  if pgrep -f "wmctrl -t" >/dev/null; then
    log "WARNING: Unauthorized attempt to move workspace detected. Killing offender..."
    pkill -9 -f "wmctrl -t" || true
    return 1
  fi
  return 0
}

daemon_loop() {
  log "Policy Engine Daemon STARTED."
  while true; do
    check_integrity || true
    check_workspaces || true
    sleep 0.5
  done
}

case "$risk" in
  show)
    echo "policies: low, medium, high, start"
    ;;
  start)
    mkdir -p "$(dirname "$DAEMON_LOG")"
    nohup bash "$0" daemon >> "$DAEMON_LOG" 2>&1 &
    log "Daemon launched in background. PID: $!"
    ;;
  daemon)
    daemon_loop
    ;;
  low)
    ./scripts/mode_full.sh >/dev/null
    echo "POLICY_APPLIED:low"
    ;;
  medium)
    ./scripts/mode_safe.sh >/dev/null
    echo "POLICY_APPLIED:medium"
    ;;
  high)
    ./scripts/mode_safe.sh >/dev/null
    echo "POLICY_APPLIED:high + manual approvals required"
    ;;
  check)
    [ -x ./scripts/mode_full.sh ] && [ -x ./scripts/mode_safe.sh ]
    [ -f "$CONFIG_FILE" ]
    echo "POLICY_ENGINE_OK"
    ;;
  *)
    echo "usage: $0 {show|low|medium|high|check|start}" >&2
    exit 2
    ;;
esac
