#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.openclaw/bin:$PATH"

ALLOW="DOCS/allowlist_plugins.txt"
[ -f "$ALLOW" ] || { echo "FAIL: missing $ALLOW" >&2; exit 1; }

want="$(sed '/^\s*$/d' "$ALLOW" | sort -u)"
out="$(openclaw plugins list 2>&1 || true)"

have="$(printf "%s\n" "$out" \
  | awk -F'│' 'tolower($4) ~ /loaded/ {gsub(/^[ \t]+|[ \t]+$/,"",$3); if($3!="") print $3}' \
  | sed '/^\s*$/d' | sort -u)"

if [ "$have" != "$want" ]; then
  echo "FAIL: loaded plugins differ from allowlist" >&2
  echo "== want ==" >&2
  printf "%s\n" "$want" >&2
  echo "== have ==" >&2
  printf "%s\n" "$have" >&2
  exit 2
fi

printf "%s\n" "$have" | grep -qx "lobster" || { echo "FAIL: lobster not loaded" >&2; exit 3; }

status="$(openclaw status 2>&1 || true)"
printf "%s\n" "$status" | grep -Eiq 'WhatsApp.*│[[:space:]]*OFF' || {
  echo "FAIL: WhatsApp channel is not OFF" >&2
  printf "%s\n" "$status" | grep -Ei 'WhatsApp' >&2 || true
  exit 4
}

echo "OK" >&2
