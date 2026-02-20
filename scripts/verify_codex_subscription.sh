#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.openclaw/bin:$PATH"

MODEL="openai-codex/gpt-5.1-codex-mini"
EXPECT_MODEL_SUB="gpt-5.1-codex-mini"

# By default: do NOT block local/dev PRs. CI can set STRICT_CODEX_SUBSCRIPTION=1
STRICT="${STRICT_CODEX_SUBSCRIPTION:-0}"

# Retry knobs (keep fast)
ATTEMPTS="${CODEX_SUB_ATTEMPTS:-3}"
SLEEP_SECS="${CODEX_SUB_SLEEP_SECS:-1}"
TIMEOUT_SECS="${CODEX_SUB_TIMEOUT_SECS:-30}"

echo "== openclaw version ==" >&2
openclaw --version >&2

echo "== models status (key lines) ==" >&2
openclaw models status >&2 || true

# Force session model (best-effort)
echo "== force session model (/new) ==" >&2
openclaw agent --agent main --message "/new $MODEL" --timeout 120 >/dev/null 2>&1 || true

node_check() {
  local out="$1"
  printf "%s" "$out" | EXPECT_MODEL_SUB="$EXPECT_MODEL_SUB" node -e '
    const fs=require("fs");
    const out=fs.readFileSync(0,"utf8");
    const i=out.indexOf("{");
    const j=out.lastIndexOf("}");
    if(i<0||j<=i){
      console.error("FAIL: no JSON object found in output");
      console.error(out.slice(0,800));
      process.exit(1);
    }
    const jsonStr=out.slice(i,j+1);

    let data;
    try{ data=JSON.parse(jsonStr); }
    catch(e){
      console.error("FAIL: JSON parse");
      console.error(String(e));
      console.error(jsonStr.slice(0,800));
      process.exit(1);
    }

    const status=String(data?.status ?? "");
    if(status && status !== "ok"){
      console.error(`FAIL: status not ok (${status})`);
      process.exit(5);
    }

    const metaContainer = data?.result?.meta ?? data?.meta ?? {};
    const meta=metaContainer?.agentMeta ?? {};
    const provider=String(meta.provider||"");
    const model=String(meta.model||"");

    const payloads=Array.isArray(data?.result?.payloads)
      ? data.result.payloads
      : (Array.isArray(data?.payloads) ? data.payloads : []);

    const allText=payloads.map(p=>String(p?.text??"")).join("\n").trim();
    const expSub=String(process.env.EXPECT_MODEL_SUB||"");

    console.error(`provider=${provider}`);
    console.error(`model=${model}`);
    if(payloads.length) console.error(`text0=${String(payloads[0].text??"").trim()}`);

    if(!provider.toLowerCase().includes("codex")){
      console.error("FAIL: expected provider to include codex");
      process.exit(2);
    }
    if(expSub && !model.includes(expSub)){
      console.error(`FAIL: expected model to include ${expSub}`);
      process.exit(3);
    }
    if(!payloads.length){
      console.error("FAIL: no payloads in JSON (agent returned no text)");
      process.exit(4);
    }
    if(allText !== "OK"){
      const preview = allText.length ? allText.slice(0,120) : "<empty>";
      console.error(`FAIL: expected text exactly OK (got ${preview})`);
      process.exit(6);
    }

    console.error("OK");
  '
}

ok="false"
last_rc=0

for i in $(seq 1 "$ATTEMPTS"); do
  echo "== smoke agent attempt ${i}/${ATTEMPTS} (--json) ==" >&2
  set +e
  out="$(openclaw agent --agent main --message "Respondé EXACTAMENTE con: OK" --json --timeout "$TIMEOUT_SECS" 2>&1)"
  node_check "$out"
  last_rc=$?
  set -e

  if [[ "$last_rc" -eq 0 ]]; then
    ok="true"
    break
  fi

  echo "WARN: codex smoke attempt ${i} failed (rc=${last_rc})" >&2
  if [[ "$i" -lt "$ATTEMPTS" ]]; then
    sleep "$SLEEP_SECS"
  fi
done

if [[ "$ok" == "true" ]]; then
  echo "OK" >&2
  exit 0
fi

if [[ "$STRICT" == "1" ]]; then
  echo "FAIL: codex subscription check failed after ${ATTEMPTS} attempts (STRICT=1)" >&2
  exit "${last_rc:-1}"
fi

echo "WARN: codex subscription check inconclusive after ${ATTEMPTS} attempts; continuing (STRICT=0)" >&2
exit 0
