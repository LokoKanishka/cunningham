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
  # Intentamos reinicio por systemd user service
  if systemctl --user is-active --quiet openclaw-gateway.service 2>/dev/null; then
    systemctl --user restart openclaw-gateway.service || true
  else
    log "Fallback: Starting gateway foreground..."
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
  local services=("lucy_brain_n8n" "lucy_eyes_searxng" "lucy_ui_panel" "lucy_memory_redis")
  local unhealthy=0
  for s in "${services[@]}"; do
    if ! docker ps --filter "name=$s" --filter "status=running" | grep -q "$s"; then
      log "WARNING: Container $s is DOWN. Restarting infra..."
      # compose_infra might need sudo depending on docker setup, keeping it as is if it was working
      ./scripts/compose_infra.sh up -d "$s" || true
      unhealthy=$((unhealthy + 1))
    fi
  done
  return $unhealthy
}

# 3. Monitoreo de Interfaz (Direct Chat) y Limpieza UI
check_ui() {
  # Verificamos si el proceso de python del direct chat está vivo
  if systemctl --user is-active --quiet openclaw-direct-chat.service 2>/dev/null; then
    if ! pgrep -f "openclaw_direct_chat.py" >/dev/null; then
      log "WARNING: Direct Chat process missing. Restarting service..."
      systemctl --user restart openclaw-direct-chat.service || true
    fi
  fi

  # Auto-reparación UI: Limpiar procesos huérfanos de Playwright/Chromium
  if pgrep -f "chromium" >/dev/null || pgrep -f "playwright" >/dev/null; then
    # Solo matamos si llevan mucho tiempo o si hay sospecha de cuelgue
    # Para simplificar V7, si detectamos muchos procesos, limpiamos para asegurar "Zero-State"
    count=$(pgrep -f "chromium" | wc -l)
    if [ "$count" -gt 15 ]; then
      log "WARNING: detected $count chromium processes. Cleaning up for stability..."
      pkill -f "chromium" || true
      pkill -f "playwright" || true
    fi
  fi
}

# 4. Monitoreo del Watcher
check_watcher() {
  if ! systemctl --user is-active --quiet openclaw-watcher.service 2>/dev/null; then
    log "WARNING: Watcher service DOWN. Restarting..."
    systemctl --user restart openclaw-watcher.service || true
  fi
}

main() {
  log "Health check start..."
  check_gateway || true
  check_infra || true
  check_ui || true
  check_watcher || true
  log "Health check complete."
}

main "$@"
