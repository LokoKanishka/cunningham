#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$PWD}"
echo "Watcher Daemon started for: $ROOT_DIR" >&2

# 1. Asegurar que las dependencias sean ejecutables
chmod +x "$ROOT_DIR/scripts/watch_workspace.sh"
chmod +x "$ROOT_DIR/scripts/goals_queue.sh"
chmod +x "$ROOT_DIR/scripts/goals_worker.sh"

# 2. Iniciar el worker en background (loop infinito)
export GOALS_WORKER_LOOPS=999999999
"$ROOT_DIR/scripts/goals_worker.sh" run &
WORKER_PID=$!

cleanup() {
  echo "Stopping Watcher Daemon (Killing worker $WORKER_PID)..." >&2
  kill "$WORKER_PID" || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# 3. Consumir el watcher eternamente
"$ROOT_DIR/scripts/watch_workspace.sh" "$ROOT_DIR" | while read -r line; do
  # El formato de log del watcher variará según inotify o polling pero 
  # buscamos cualquier evento que marque TAREA.md en $ROOT_DIR.
  if printf "%s" "$line" | grep -q "TAREA.md"; then
    if [ -s "$ROOT_DIR/TAREA.md" ]; then
      goal="$(cat "$ROOT_DIR/TAREA.md")"
      echo "[Event] TAREA.md modificado. Encolando objetivo: $goal" >&2
      
      # Encolar y vaciar
      cd "$ROOT_DIR" && ./scripts/goals_queue.sh add "$goal"
      > "$ROOT_DIR/TAREA.md"
    fi
  fi
done

wait
