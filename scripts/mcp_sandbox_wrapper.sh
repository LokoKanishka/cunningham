#!/usr/bin/env bash
set -euo pipefail

# mcp_sandbox_wrapper.sh — Entorno de "confianza cero" para herramientas MCP externas.
# Usa bubblewrap para aislar el proceso del sistema principal y archivos sensibles.

if ! command -v bwrap >/dev/null 2>&1; then
  echo "ERROR: bwrap not found. Cannot ensure Zero-State Sandbox. Aborting." >&2
  exit 1
fi

if [ "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null)" = "1" ]; then
  echo "ERROR: AppArmor is blocking unprivileged user namespaces." >&2
  echo "To enable bubblewrap sandboxing, run on the host:" >&2
  echo "  sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0" >&2
  echo "Zero-State execution aborted to prevent insecure fallback." >&2
  exit 1
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

args=(
  --unshare-all
  --share-net
  --new-session
  --die-with-parent
  --ro-bind /usr /usr
  --ro-bind /lib /lib
  --ro-bind /bin /bin
  --ro-bind /sbin /sbin
  --ro-bind /etc/resolv.conf /etc/resolv.conf
  --ro-bind /etc/ssl /etc/ssl
  --ro-bind /etc/hosts /etc/hosts
  --proc /proc
  --dev /dev
  --tmpfs /tmp
  --dir /run --tmpfs /run
  --dir /var --tmpfs /var
  --dir "$HOME"
  --dir "$HOME/.cache" --tmpfs "$HOME/.cache"
  --dir "$HOME/.npm" --tmpfs "$HOME/.npm"
  --dir "/workspace" --tmpfs "/workspace"
  --ro-bind "$REPOS_DIR" "$REPOS_DIR"
  --ro-bind "$HOME/Escritorio/cunningham-verde" "$HOME/Escritorio/cunningham-verde"
  --chdir "/workspace"
  --setenv HOME "$HOME"
  --setenv PATH "/usr/local/bin:/usr/bin:/bin"
)

if [ -d /lib64 ]; then args+=( --ro-bind /lib64 /lib64 ); fi
if [ -d /etc/pki ]; then args+=( --ro-bind /etc/pki /etc/pki ); fi

exec bwrap "${args[@]}" -- "$@"
