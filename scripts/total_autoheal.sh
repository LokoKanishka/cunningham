#!/usr/bin/env bash
set -euo pipefail

# total_autoheal.sh — Sanación total del ecosistema Cunningham Verde.
# Monitorea y repara: Gateway, Contenedores Docker e Interfaz.

logf="${TOTAL_AUTOHEAL_LOG:-DOCS/RUNS/total_autoheal.log}"
mkdir -p "$(dirname "$logf")"

log() {
  echo "$(date -Is) [autoheal] $1" | tee -a "$logf"
}

# 1. Monitoreo del Gateway (OpenClaw)
check_gateway() {
  if openclaw health >/dev/null 2>&1; then
    return 0
  fi
  log "CRITICAL: Gateway DOWN. Attempting restart..."
  # Intentamos reinicio por systemd si existe, sino por binario
  if systemctl is-active --quiet openclaw-gateway.service 2>/dev/null; then
    sudo systemctl restart openclaw-gateway.service || true
  else
    nohup openclaw gateway --force >/tmp/openclaw-gateway-autoheal.log 2>&1 &
  fi
  sleep 5
  if openclaw health >/dev/null 2>&1; then
    log "SUCCESS: Gateway RECOVERED."
    return 0
  fi
  log "ERROR: Gateway recovery FAILED."
  return 1
}

# 2. Monitoreo de Infraestructura (Docker)
check_infra() {
  local services=("lucy_brain_n8n" "lucy_hands_antigravity" "lucy_eyes_searxng")
  local unhealthy=0
  for s in "${services[@]}"; do
    if ! docker ps --filter "name=$s" --filter "status=running" | grep -q "$s"; then
      log "WARNING: Container $s is DOWN. Restarting infra..."
      ./scripts/compose_infra.sh up -d "$s" || true
      unhealthy=$((unhealthy + 1))
    fi
  done
  return $unhealthy
}

# 3. Monitoreo de Interfaz (Direct Chat)
check_ui() {
  # Verificamos si el proceso de python del direct chat está vivo si el service se reporta como activo
  if systemctl is-active --quiet openclaw-direct-chat.service 2>/dev/null; then
    if ! pgrep -f "openclaw_direct_chat.py" >/dev/null; then
      log "WARNING: Direct Chat process missing. Restarting service..."
      sudo systemctl restart openclaw-direct-chat.service || true
    fi
  fi
}

main() {
  log "Health check start..."
  check_gateway || true
  check_infra || true
  check_ui || true
  log "Health check complete."
}

main "$@"
