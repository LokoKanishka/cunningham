#!/usr/bin/env bash
# verify_watcher.sh — smoke-test for the Autonomous Watcher ecosystem
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ERRORS=0

pass() { printf "  \033[32mOK\033[0m  %s\n" "$1"; }
fail() { printf "  \033[31mFAIL\033[0m %s\n" "$1"; ERRORS=$((ERRORS+1)); }

echo "=== verify_watcher ==="

# 1. Componentes disponibles y ejecutables
for f in scripts/watch_workspace.sh scripts/goals_queue.sh scripts/goals_worker.sh scripts/watcher_daemon.sh; do
  if [ -x "$f" ]; then
    pass "$f ejecutable"
  else
    fail "$f no encontrado o no ejecutable"
    chmod +x "$f" 2>/dev/null || true
  fi
done

# 2. Checks de auto-diagnóstico de cada componente
result="$(./scripts/watch_workspace.sh . check 2>/dev/null || echo '')"
if printf '%s' "$result" | grep -q "^WATCHER_OK"; then
  pass "watch_workspace.sh check: $result"
else
  fail "watch_workspace.sh check falló (got: '$result')"
fi

result="$(GOALS_FILE=/tmp/goals_verify_$$.jsonl ./scripts/goals_queue.sh check 2>/dev/null || echo '')"
if [ "$result" = "GOALS_QUEUE_OK" ]; then
  pass "goals_queue.sh check: $result"
else
  fail "goals_queue.sh check falló (got: '$result')"
fi

result="$(./scripts/goals_worker.sh check 2>/dev/null || echo '')"
if [ "$result" = "GOALS_WORKER_OK" ]; then
  pass "goals_worker.sh check: $result"
else
  fail "goals_worker.sh check falló (got: '$result')"
fi

# 3. Smoke test: add → next → run_once → done
TMP_GOALS="/tmp/goals_watcher_smoke_$$.jsonl"
export GOALS_FILE="$TMP_GOALS"

ADD_OUT="$(./scripts/goals_queue.sh add "Genera un JSON con clave saludo y valor hola" 2>/dev/null)"
GOAL_ID="$(printf '%s' "$ADD_OUT" | sed 's/^ADDED://')"

if [ -n "$GOAL_ID" ]; then
  pass "goals_queue.sh add → ID=$GOAL_ID"
else
  fail "goals_queue.sh add no devolvió ID"
fi

NEXT_OUT="$(./scripts/goals_queue.sh next 2>/dev/null)"
if printf '%s' "$NEXT_OUT" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); assert o["status"]=="todo"' 2>/dev/null; then
  pass "goals_queue.sh next devuelve objetivo todo"
else
  fail "goals_queue.sh next no devolvió objetivo todo"
fi

mkdir -p DOCS/RUNS
RUN_OUT="$(./scripts/goals_worker.sh once 2>/dev/null)"
if printf '%s' "$RUN_OUT" | grep -q "^DONE:$GOAL_ID"; then
  pass "goals_worker.sh once ejecutó y marcó done: $RUN_OUT"
else
  fail "goals_worker.sh once no completó objetivo (got: '$RUN_OUT')"
fi

DONE_OUT="$(./scripts/goals_queue.sh done "$GOAL_ID" 2>/dev/null || echo '')"
# El worker ya llama done, puede devolver NO_CHANGE — ambos son OK
if [ "$DONE_OUT" = "DONE" ] || [ "$DONE_OUT" = "NO_CHANGE" ]; then
  pass "goals_queue.sh done idempotente: $DONE_OUT"
else
  fail "goals_queue.sh done inesperado (got: '$DONE_OUT')"
fi

rm -f "$TMP_GOALS"

# 4. Verificar unidad systemd
if [ -f "systemd/watcher-daemon.service" ]; then
  pass "systemd/watcher-daemon.service existe"
else
  fail "systemd/watcher-daemon.service no encontrado"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "VERIFY_WATCHER_OK"
else
  echo "VERIFY_WATCHER_FAIL errors=$ERRORS" >&2
  exit 1
fi
