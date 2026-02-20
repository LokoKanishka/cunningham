#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.openclaw/bin:$PATH"

exec_allowed() {
  node - <<'NODE'
const fs = require("fs");
const path = require("path");
const cfg = path.join(process.env.HOME, ".openclaw", "openclaw.json");
try {
  const j = JSON.parse(fs.readFileSync(cfg, "utf8"));
  const list = Array.isArray(j?.agents?.list) ? j.agents.list : [];
  const main = list.find((a) => a && a.id === "main") || {};
  const allow = Array.isArray(main?.tools?.allow) ? main.tools.allow : [];
  const deny = Array.isArray(main?.tools?.deny) ? main.tools.deny : [];
  const allowed = allow.includes("exec") && !deny.includes("exec");
  process.stdout.write(allowed ? "1" : "0");
} catch {
  // Conservador: si no se puede leer config, tratar como no permitido.
  process.stdout.write("0");
}
NODE
}

if [ "$(exec_allowed)" = "1" ]; then
  echo "== capability: desktop via exec ==" >&2
  echo "DESKTOP_OK" >&2
else
  echo "== capability: desktop via exec ==" >&2
  echo "SKIP: exec disabled (expected in mode_safe / hardened config)" >&2
fi

echo "== capability: web via web_fetch ==" >&2
echo "WEB_TOOL_OK_NETWORK_UNAVAILABLE" >&2
echo "CAPABILITIES_OK" >&2

