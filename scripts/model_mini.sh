#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.openclaw/bin:$PATH"
m="openai-codex/gpt-5.1-codex-mini"
openclaw models set "$m" 1>&2
# Manda un mensaje de limpieza dura de sesion para soltar memoria/contexto
openclaw agent --agent main --message "/new $m" --json --timeout 120 >/dev/null 2>&1 || true
# Limpia kill de posibles inferencias huerfanas de python locales del modelo viejo (Fail-Safe)
pkill -f "ollama run" 2>/dev/null || true
openclaw models status 1>&2
