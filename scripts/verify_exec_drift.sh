#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.openclaw/openclaw.json"
if [ ! -f "$CFG" ]; then
  echo "WARN: missing $CFG (cannot check exec drift)" >&2
  exit 0
fi

node - "$CFG" <<'NODE'
const fs = require("fs");
const cfg = process.argv[2];
const j = JSON.parse(fs.readFileSync(cfg, "utf8"));
const list = Array.isArray(j?.agents?.list) ? j.agents.list : [];
const main = list.find((a) => a && a.id === "main") || {};
const allow = Array.isArray(main?.tools?.allow) ? main.tools.allow : [];
const deny = Array.isArray(main?.tools?.deny) ? main.tools.deny : [];

const execEnabled = allow.includes("exec") && !deny.includes("exec");
const bashDenied = deny.includes("bash");

if (execEnabled) {
  console.error("WARN_EXEC_ENABLED: 'exec' esta habilitado para el agente main.");
  console.error("  Esto SOLO es esperable en modo full. Si no lo querias, corre: ./scripts/mode_safe.sh");
  console.error("  allow:", JSON.stringify(allow));
  console.error("  deny :", JSON.stringify(deny));
  process.exit(0);
}

console.error("OK_EXEC_DISABLED: exec no esta habilitado (safe/hardened).");
if (!bashDenied) {
  console.error("WARN: bash no esta en deny (recomendado agregarlo).");
}
process.exit(0);
NODE
