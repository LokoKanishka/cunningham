#!/usr/bin/env bash
set -euo pipefail

# watcher_daemon.sh — Watcher for Cunningham Verde
# Monitors TAREA.md and triggers goals_worker.sh

ROOT_DIR="/home/lucy-ubuntu/Escritorio/cunningham-verde"
cd "$ROOT_DIR"

mkdir -p DOCS/RUNS

log() {
  echo "$(date -Is) [watcher] $1" >> DOCS/RUNS/watcher_daemon.log
}

log "Starting Watcher Daemon..."

# Ensure goals scripts are executable
chmod +x "$ROOT_DIR/scripts/goals_queue.sh"
chmod +x "$ROOT_DIR/scripts/goals_worker.sh"
chmod +x "$ROOT_DIR/scripts/watch_workspace.sh"

# 1. Start the worker in background
export GOALS_WORKER_LOOPS=999999999
"$ROOT_DIR/scripts/goals_worker.sh" run &
WORKER_PID=$!

cleanup() {
  log "Stopping Watcher Daemon (Killing worker $WORKER_PID)..."
  kill "$WORKER_PID" || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# 2. Watch TAREA.md
"$ROOT_DIR/scripts/watch_workspace.sh" "$ROOT_DIR" | while read -r line; do
  if printf "%s" "$line" | grep -q "TAREA.md"; then
    if [ -s "$ROOT_DIR/TAREA.md" ]; then
      goal="$(cat "$ROOT_DIR/TAREA.md")"
      log "TAREA.md detected. Enqueuing goal: $goal"
      
      ./scripts/goals_queue.sh add "$goal"
      > "$ROOT_DIR/TAREA.md"
    fi
  fi
done

wait
