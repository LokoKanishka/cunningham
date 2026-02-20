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
  out_desktop="$(openclaw agent --agent main --json --timeout 120 \
    --message 'Usá la herramienta exec para listar el escritorio con: ls -1 ~/Escritorio | head -n 20.
Respondé EXACTAMENTE con DESKTOP_OK si ves la carpeta cunningham; si no, DESKTOP_FAIL.' \
    2>&1 || true)"

  printf "%s" "$out_desktop" | node -e '
const fs=require("fs");
const raw=fs.readFileSync(0,"utf8");
const i=raw.indexOf("{");
const j=raw.lastIndexOf("}");
if(i<0||j<=i){ console.error("FAIL: desktop no JSON"); process.exit(1); }
let data;
try { data=JSON.parse(raw.slice(i,j+1)); } catch(e){ console.error("FAIL: desktop JSON parse"); process.exit(1); }
const payloads=Array.isArray(data?.result?.payloads) ? data.result.payloads : (Array.isArray(data?.payloads) ? data.payloads : []);
const text=payloads.map(p=>String(p?.text??"")).join("\n").trim();
if(text!=="DESKTOP_OK"){
  console.error("FAIL: desktop expected DESKTOP_OK");
  console.error(text.slice(0,500));
  process.exit(2);
}
console.error("DESKTOP_OK");
'
else
  echo "== capability: desktop via exec ==" >&2
  echo "SKIP: exec disabled (expected in mode_safe / hardened config)" >&2
fi

echo "== capability: web via web_fetch ==" >&2
out_web="$(openclaw agent --agent main --json --timeout 120 \
  --message 'Usá la herramienta web_fetch para leer https://example.com y devolvé en una sola línea: RESULT=<ok|fail> REASON=<motivo corto>. Si no tenés la tool, devolvé RESULT=fail REASON=no_tool.' \
  2>&1 || true)"

printf "%s" "$out_web" | node -e '
const fs=require("fs");
const raw=fs.readFileSync(0,"utf8");
const i=raw.indexOf("{");
const j=raw.lastIndexOf("}");
if(i<0||j<=i){ console.error("FAIL: web no JSON"); process.exit(1); }
let data;
try { data=JSON.parse(raw.slice(i,j+1)); } catch(e){ console.error("FAIL: web JSON parse"); process.exit(1); }
const payloads=Array.isArray(data?.result?.payloads) ? data.result.payloads : (Array.isArray(data?.payloads) ? data.payloads : []);
const text=payloads.map(p=>String(p?.text??"")).join("\n").trim();
const low=text.toLowerCase();
if(low.includes("result=ok")){
  console.error("WEB_OK");
  process.exit(0);
}
if(low.includes("no_tool") || low.includes("no disponible") || low.includes("not available")){
  console.error("FAIL: web tool unavailable");
  console.error(text.slice(0,500));
  process.exit(2);
}
if(low.includes("enotfound") || low.includes("eai_again") || low.includes("timed out") || low.includes("network") || low.includes("dns")){
  console.error("WEB_TOOL_OK_NETWORK_UNAVAILABLE");
  process.exit(0);
}
console.error("FAIL: unexpected web result");
console.error(text.slice(0,500));
process.exit(3);
'

echo "CAPABILITIES_OK" >&2
