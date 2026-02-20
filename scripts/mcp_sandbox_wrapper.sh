#!/usr/bin/env bash
set -euo pipefail

# mcp_sandbox_wrapper.sh — Entorno de "confianza cero" para herramientas MCP externas.
# Usa bubblewrap para aislar el proceso del sistema principal y archivos sensibles.

if ! command -v bwrap >/dev/null 2>&1; then
  echo "WARNING: bwrap not found. Running command WITHOUT sandbox!" >&2
  exec "$@"
fi

# Directorio de los repos comunitarios
REPOS_DIR="${COMMUNITY_ROOT:-$HOME/Escritorio/cunningham-verde/community/mcp/repos}"
mkdir -p "$REPOS_DIR"

# Argumentos de bwrap:
# --unshare-all: Aisla network, ipc, uts, user, pid (requiere kernel compatible).
# --share-net: Permitimos red (requerido por Cloudflare, Exa, Arxiv, etc).
# --new-session: Evita escape a la terminal controladora.
# --die-with-parent: Cierra el sandbox si el wrapper muere.
# --ro-bind: Monta directorios de sistema como Read-Only.
# --tmpfs: Monta sistemas de archivos temporales en memoria para /tmp, /run, etc.

# Nota: No montamos ~/.ssh ni ~/.openclaw ni archivos de configuración de n8n.
# Permitimos ~/.cache y ~/.npm para que uvx/npx funcionen razonablemente rápido.

bwrap \
  --unshare-all \
  --share-net \
  --new-session \
  --die-with-parent \
  --ro-bind /usr /usr \
  --ro-bind /lib /lib \
  --ro-bind /lib64 /lib64 2>/dev/null || true \
  --ro-bind /bin /bin \
  --ro-bind /sbin /sbin \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --ro-bind /etc/ssl /etc/ssl \
  --ro-bind /etc/pki /etc/pki 2>/dev/null || true \
  --ro-bind /etc/hosts /etc/hosts \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --dir /run --tmpfs /run \
  --dir /var --tmpfs /var \
  --dir "$HOME" \
  --bind "$HOME/.cache" "$HOME/.cache" 2>/dev/null || --tmpfs "$HOME/.cache" \
  --bind "$HOME/.npm" "$HOME/.npm" 2>/dev/null || --tmpfs "$HOME/.npm" \
  --bind "$(pwd)" "$(pwd)" \
  --bind "$REPOS_DIR" "$REPOS_DIR" \
  --chdir "$(pwd)" \
  --setenv HOME "$HOME" \
  --setenv PATH "/usr/local/bin:/usr/bin:/bin" \
  -- "$@"
