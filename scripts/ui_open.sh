#!/usr/bin/env bash
[ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && { echo "ERROR: No display detected" >&2; exit 1; }
set -euo pipefail

URL="http://127.0.0.1:5001"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 || true
fi

echo "UI_URL=$URL"
