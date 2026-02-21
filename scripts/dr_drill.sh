#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# dr_drill.sh — Cunningham Verde: Disaster Recovery Drill (E1)
# 1. Trigger controlled chaos
# 2. Wait for autosanación (total_autoheal.sh)
# 3. Verify total system integrity

log() {
  echo "$(date -Is) [dr-drill] $1"
}

export CHAOS_ENABLED=true
export CHAOS_LOG="DOCS/RUNS/chaos_drill.log"

log "Step 1: Triggering Chaos..."
./scripts/chaos_cunningham.sh

log "Step 2: Allowing time for systems to fail/detect..."
sleep 5

log "Step 3: Triggering Total Autoheal..."
./scripts/total_autoheal.sh

log "Step 4: Cooling down..."
sleep 10

log "Step 5: Verifying all systems..."
if ./scripts/verify_all.sh; then
  log "SUCCESS: System survived the chaos and recovered."
  echo "DR_DRILL=PASS"
  exit 0
else
  log "ERROR: System failed to recover fully."
  echo "DR_DRILL=FAIL"
  exit 1
fi
