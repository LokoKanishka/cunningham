#!/usr/bin/env bash
set -euo pipefail

echo "== verify_gateway ==" >&2
./scripts/verify_gateway.sh
echo "== verify_plugins ==" >&2
./scripts/verify_plugins.sh 1>&2
echo "== verify_lobster ==" >&2
./scripts/verify_lobster.sh 1>&2

echo "== verify_capabilities ==" >&2
./scripts/verify_capabilities.sh 1>&2

echo "== verify_exec_drift ==" >&2
./scripts/verify_exec_drift.sh 1>&2

echo "== verify_codex_subscription ==" >&2
./scripts/verify_codex_subscription.sh

echo "== verify_security_audit ==" >&2
./scripts/verify_security_audit.sh

echo "== verify_community_mcp ==" >&2
./scripts/community_mcp.sh check 1>&2

echo "== verify_watcher ==" >&2
./scripts/verify_watcher.sh 1>&2

echo "== verify_zero_state ==" >&2
./scripts/verify_zero_state.sh 1>&2

echo "== verify_ui_vision_assert ==" >&2
./scripts/ui_vision_assert.sh 1>&2

echo "== verify_n8n_orchestration ==" >&2
./scripts/n8n_stress.sh >/dev/null 2>&1

echo "ALL_OK" >&2
