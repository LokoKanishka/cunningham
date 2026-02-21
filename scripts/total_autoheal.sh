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
  # Mapeo de nombre de contenedor a nombre de servicio en docker-compose.yml
  declare -A service_map=(
    ["lucy_brain_n8n"]="n8n"
    ["lucy_eyes_searxng"]="searxng"
    ["lucy_ui_panel"]="lucy_ui_panel"
    ["lucy_memory_redis"]="redis"
    ["lucy_memory_qdrant"]="qdrant"
    ["lucy_hands_antigravity"]="antigravity"
  )

  local unhealthy=0
  for container in "${!service_map[@]}"; do
    local service="${service_map[$container]}"
    if ! docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
      log "WARNING: Container $container is DOWN. Cleaning up and restarting service $service..."
      docker rm -f "$container" >/dev/null 2>&1 || true
      ./scripts/compose_infra.sh up -d "$service" || true
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
   if pgrep -f "chromium" >/dev/null || pgrep -f "playwright" >/dev/null || pgrep -f "node" >/dev/null || pgrep -x "nc" >/dev/null; then
     # Limpieza agresiva de zombies y procesos colgados
     log "Cleaning up potentially stuck processes (chromium, playwright, node, nc)..."
     pkill -9 -f "chromium" || true
     pkill -9 -f "chrome" || true
     pkill -9 -f "playwright" || true
     pkill -9 -x "nc" || true
     # Note: node is critical for n8n, so only kill if it's not managed properly?
     # Actually, check_infra handles restarting n8n container, so pkill on host's node is fine if any.
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
