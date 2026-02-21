#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.openclaw/bin:$PATH"

log() {
  echo "$(date -Is) [web-research] $1"
}

mkdir -p DOCS/RUNS
cmd="${1:-check}"
shift || true

case "$cmd" in
  check)
    [ -x ./scripts/browser_vision.sh ]
    openclaw agent --help >/dev/null
    echo "WEB_RESEARCH_OK"
    ;;
  run)
    q="${*:-openclaw plugins security best practices}"
    ts="$(date +%Y%m%d_%H%M%S)"
    out="DOCS/RUNS/web_research_${ts}.md"
    
    log "Running local research for: $q"
    raw="$(./scripts/display_isolation.sh run headless -- node scripts/web_research_playwright.js "$q")"

    text="$(printf "%s" "$raw" | node -e '
const fs=require("fs");
const raw=fs.readFileSync(0,"utf8");
try{
  const o=JSON.parse(raw);
  const md = o.results.map(r => `### [${r.url}](${r.url})\n\n${r.text}`).join("\n\n");
  console.log(md);
}catch(e){ console.log("PARSE_FAIL: " + e.message); }
')"

    {
      echo "# Web Research"
      echo
      echo "Query: $q"
      echo "Generated: $(date -Is)"
      echo
      echo "$text"
    } > "$out"

    echo "WEB_RESEARCH_OUT:$out"
    ;;
  *)
    echo "usage: $0 {check|run <query...>}" >&2
    exit 2
    ;;
esac
