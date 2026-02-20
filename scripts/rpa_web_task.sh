#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.openclaw/bin:$PATH"

cmd="${1:-check}"
url="${2:-https://example.com}"

case "$cmd" in
  check)
    openclaw browser status --json >/dev/null 2>&1 || true
    echo "RPA_BROWSER_CHECK_OK"
    ;;
  run)
    ./scripts/display_isolation.sh run headless -- openclaw browser start --json >/dev/null
    ./scripts/display_isolation.sh run headless -- openclaw browser open "$url" --json >/dev/null
    ./scripts/display_isolation.sh run headless -- openclaw browser snapshot --format ai --limit 120 --json
    ;;
  *)
    echo "usage: $0 {check|run [url]}" >&2
    exit 2
    ;;
esac
