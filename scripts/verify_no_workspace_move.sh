#!/usr/bin/env bash
# verify_no_workspace_move.sh — CI guard: ensures no script moves windows across workspaces.
# Exit 0 = clean, exit 1 = violation found.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PATTERNS=(
  'wmctrl -[ir].*-t '     # wmctrl move-to-desktop
  'wmctrl -s '            # wmctrl switch-desktop
  'xdotool set_desktop'   # xdotool switch-desktop
)

violations=0
for pat in "${PATTERNS[@]}"; do
  hits="$(grep -rnE "$pat" "$ROOT_DIR/scripts" --include='*.sh' --include='*.py' 2>/dev/null || true)"
  if [[ -n "$hits" ]]; then
    echo "VIOLATION: pattern '$pat' found:" >&2
    echo "$hits" >&2
    violations=$((violations + 1))
  fi
done

if [[ "$violations" -gt 0 ]]; then
  echo "FAIL: $violations workspace-movement pattern(s) detected." >&2
  exit 1
fi

echo "OK: no workspace-movement commands found." >&2
exit 0
