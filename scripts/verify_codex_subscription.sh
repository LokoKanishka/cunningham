#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.openclaw/bin:$PATH"

echo "== openclaw version =="
openclaw --version

echo "== models status (key lines) =="
openclaw models status 1>&2 || true

echo "== smoke agent =="
out="$(openclaw agent --agent main --message "Respondé exactamente con: OK" 2>&1 | tail -n 1)"
if [[ "$out" != "OK" ]]; then
  echo "FAIL: expected OK, got: $out" >&2
  exit 1
fi
echo "OK"
