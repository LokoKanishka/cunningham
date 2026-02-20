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
)

# Seleccionar una atrocidad al azar
target="${atrocities[$RANDOM % ${#atrocities[@]}]}"

log "Selected target: $target"

case "$target" in
  kill_n8n)
    log "Action: Killing lucy_brain_n8n container"
    docker kill lucy_brain_n8n >/dev/null 2>&1 || true
    ;;
  kill_antigravity)
    log "Action: Killing lucy_hands_antigravity container"
    docker kill lucy_hands_antigravity >/dev/null 2>&1 || true
    ;;
  kill_gateway)
    log "Action: SIGKILL on openclaw gateway"
    pkill -9 -f "openclaw gateway" || true
    ;;
  kill_direct_chat)
    log "Action: SIGKILL on openclaw_direct_chat.py"
    pkill -9 -f "openclaw_direct_chat.py" || true
    ;;
  kill_browsers)
    log "Action: Force closing Playwright/Chrome processes"
    pkill -9 -f "chrome|chromium|firefox" || true
    ;;
esac

log "Atrocity completed."
exit 0
