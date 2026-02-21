#!/usr/bin/env bash
set -euo pipefail

# chaos_cunningham.sh — Horizonte Verde E1: Ingeniería del Caos Continua
# Selecciona aleatoriamente un objetivo crítico y lo destruye para probar la autosanación.

logf="${CHAOS_LOG:-DOCS/RUNS/chaos.log}"
mkdir -p "$(dirname "$logf")"

log() {
  echo "$(date -Is) [CHAOS] $1" | tee -a "$logf"
}

if [ "${CHAOS_ENABLED:-false}" != "true" ]; then
  echo "Chaos monkey disabled. Set CHAOS_ENABLED=true to run."
  exit 0
fi

# Lista de atrocidades posibles
atrocities=(
  kill_n8n
  kill_antigravity
  kill_gateway
  kill_direct_chat
  kill_browsers
  kill_redis
  kill_searxng
  saturate_ports
  kill_mcp_bridge
)

# Seleccionar una atrocidad al azar
target="${atrocities[$RANDOM % ${#atrocities[@]}]}"

log "Selected target: $target"

case "$target" in
  kill_n8n)
    log "Action: Killing lucy_brain_n8n container (hard)"
    docker stop -t 1 lucy_brain_n8n >/dev/null 2>&1 || true
    ;;
  kill_antigravity)
    log "Action: Killing lucy_hands_antigravity container"
    docker kill lucy_hands_antigravity >/dev/null 2>&1 || true
    ;;
  kill_gateway)
    log "Action: SIGKILL on openclaw gateway"
    pkill -9 -f "openclaw gateway" || pkill -9 -f "bin/openclaw" || true
    ;;
  kill_direct_chat)
    log "Action: SIGKILL on openclaw_direct_chat.py"
    pkill -9 -f "openclaw_direct_chat.py" || true
    ;;
  kill_browsers)
    log "Action: Force closing Playwright/Chrome processes"
    pkill -9 -f "chrome|chromium|firefox" || true
    ;;
  kill_redis)
    log "Action: Killing lucy_memory_redis container"
    docker kill lucy_memory_redis >/dev/null 2>&1 || true
    ;;
  kill_searxng)
    log "Action: Killing lucy_eyes_searxng container"
    docker kill lucy_eyes_searxng >/dev/null 2>&1 || true
    ;;
  saturate_ports)
    log "Action: Simulating port saturation (5678, 9000)"
    # Use nc to listen on critical ports to block them
    (timeout 30s nc -l -p 5678 >/dev/null 2>&1 &) || true
    (timeout 30s nc -l -p 9000 >/dev/null 2>&1 &) || true
    log "Port saturation simulated for 30s."
    ;;
  kill_mcp_bridge)
    log "Action: Killing mcporter and MCP bridge processes"
    pkill -9 -f "mcporter" || true
    pkill -9 -f "community-mcp" || true
    ;;
esac

log "Atrocity completed."
exit 0
