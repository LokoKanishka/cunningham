#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.openclaw/bin:$PATH"

msg="${*:-Decime un resumen breve del estado del sistema.}"

# Usamos web_ask.py para garantizar flujo "Modo Humano" vía Playwright/DOM
raw="$(python3 scripts/molbot_direct_chat/web_ask.py --site gemini --prompt "Respondé en castellano: $msg" --headless 2>&1 || true)"

text="$(printf "%s" "$raw" | node -e '
const fs=require("fs");
const raw=fs.readFileSync(0,"utf8");
const i=raw.indexOf("{");
const j=raw.lastIndexOf("}");
if(i<0||j<=i){ console.log("No pude parsear respuesta (UI error)."); process.exit(0); }
try{
  const o=JSON.parse(raw.slice(i,j+1));
  console.log(o.text || o.evidence || "(sin texto)");
}catch{ console.log("No pude parsear respuesta (JSON error)."); }
')"

echo "$text"

if command -v spd-say >/dev/null 2>&1; then
  spd-say -l es "$text" || true
elif command -v espeak >/dev/null 2>&1; then
  espeak -v es "$text" || true
else
  echo "TTS no disponible (instalá speech-dispatcher o espeak)." >&2
fi
