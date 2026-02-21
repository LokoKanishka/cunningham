#!/usr/bin/env bash
set -euo pipefail

score_text() {
  txt="$1"
  s=0
  case "$txt" in
    *"arquitectura"*|*"refactor"*|*"vision"*|*"scrape"*|*"autonomy"*|*"debug"*) s=$((s+3));;
    *"test"*|*"suite"*|*"analiza"*|*"audit"*|*"multi"*|*"long"*|*"fix"*|*"optimiza"*|*"despliega"*|*"implementa"*|*"seguridad"*|*"vulnerabilidad"*) s=$((s+2));;
    *"bash"*|*"archivo"*|*"buscar"*) s=$((s+1));;
  esac
  case "$txt" in
    *"resumen"*|*"ping"*|*"explicá"*|*"rápido"*|*"quick"*|*"simple"*|*"1 linea"*|*"ok"*|*"typo"*|*"cambia"*|*"renombra"*|*"borra"*|*"formato"*|*"lint"*) s=$((s-1));;
  esac
  echo "$s"
}

cmd="${1:-classify}"
shift || true

case "$cmd" in
  classify)
    t="${*:-}"
    [ -n "$t" ] || { echo "usage: $0 classify <text>" >&2; exit 2; }
    l="$(printf "%s" "$t" | tr '[:upper:]' '[:lower:]')"
    words="$(printf "%s" "$l" | wc -w | awk '{print $1}')"
    s="$(score_text "$l")"
    if [ "$words" -gt 100 ]; then s=$((s+3))
    elif [ "$words" -gt 80 ]; then s=$((s+2))
    elif [ "$words" -gt 40 ]; then s=$((s+1)); fi

    mode="mini"
    model="openai-codex/gpt-5.1-codex-mini"
    if [ "$s" -ge 3 ]; then
      mode="max"; model="openai-codex/gpt-5.1-codex-max"
    elif [ "$s" -ge 1 ]; then
      mode="normal"; model="openai-codex/gpt-5.1"
    fi

    printf 'mode=%s\nmodel=%s\nscore=%s\n' "$mode" "$model" "$s"
    ;;
  check)
    echo "TASK_PROFILE_OK"
    ;;
  *)
    echo "usage: $0 {classify <text>|check}" >&2
    exit 2
    ;;
esac
