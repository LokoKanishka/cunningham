#!/usr/bin/env bash
set -euo pipefail

# Ensure we are in the project root
cd "$(dirname "$0")/.."

# Check if direct chat is up
if ! curl -s http://127.0.0.1:8787/ >/dev/null; then
    echo "ERROR: Molbot Direct Chat (dc) is not running on http://127.0.0.1:8787/"
    exit 1
fi

echo "== Phase A: Community MCP + UI Human Mode =="
node scripts/demo_community_ui_human.js
