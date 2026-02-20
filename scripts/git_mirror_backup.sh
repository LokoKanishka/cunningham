#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="."
SOURCE_URL=""
BACKUP_DIR=""
NAME=""
PUSH_URL=""
DRY_RUN="false"
ALLOW_PUSH="false"
CONFIRM_PUSH=""
PUSH_CONFIRM_TOKEN="YES_PUSH_MIRROR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S_%3N)"
LOCK_DIR=""
LOCK_HELD="false"

usage() {
  cat <<'EOF'
Uso:
  ./scripts/git_mirror_backup.sh [opciones]

Opciones:
  --repo-dir <path>     Repo local para detectar origin (default: .)
  --source-url <url>    URL origen (si no se pasa, usa remote.origin.url)
  --backup-dir <path>   Directorio base de backups (default: ./backups/git-mirror)
  --name <nombre>       Nombre del espejo (default: nombre del repo origen)
  --dry-run             No toca disco ni remotos; solo imprime el plan
  --push-url <url>      URL destino para push --mirror (requiere confirmación dura)
  --allow-push          Habilita push explícitamente (sin esto, nunca empuja)
  --confirm-push <tok>  Debe ser EXACTAMENTE: YES_PUSH_MIRROR
  -h, --help            Muestra esta ayuda

Ejemplos:
  ./scripts/git_mirror_backup.sh
  ./scripts/git_mirror_backup.sh --dry-run
  ./scripts/git_mirror_backup.sh --source-url https://github.com/org/repo.git --name backup-cunningham
  ./scripts/git_mirror_backup.sh \
    --push-url https://github.com/tu-user/repo-espejo.git \
    --allow-push --confirm-push YES_PUSH_MIRROR
EOF
}

fail() {
  echo "[git-mirror-backup] ERROR: $*" >&2
  exit 1
}

info() {
  echo "[git-mirror-backup] $*"
}

require_value() {
  local flag="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || fail "falta valor para ${flag}"
  [[ "$value" != -* ]] || fail "valor inválido para ${flag}: ${value}"
}

validate_url() {
  local label="$1"
  local value="$2"
  [[ -n "$value" ]] || fail "${label} vacío"
  [[ "$value" != *[[:space:]]* ]] || fail "${label} no puede contener espacios"
  [[ "$value" != -* ]] || fail "${label} inválido: no puede empezar con '-'"
}

validate_push_url() {
  local value="$1"
  validate_url "--push-url" "$value"

  if [[ "$value" =~ ^https?://[^/]*@ ]]; then
    fail "--push-url no debe incluir credenciales inline"
  fi

  if [[ "$value" =~ ^https?:// ]] || [[ "$value" =~ ^ssh:// ]] || [[ "$value" =~ ^git@[^:]+:.+ ]]; then
    return 0
  fi

  fail "--push-url debe ser remoto explícito (https://, ssh:// o git@host:org/repo.git)"
}

normalize_repo_id() {
  python3 - "$1" <<'PY'
import re, sys
from urllib.parse import urlparse

u = (sys.argv[1] or "").strip()

# scp-like: git@github.com:org/repo(.git)
m = re.match(r'^(?P<user>[^@]+)@(?P<host>[^:]+):(?P<path>.+)$', u)
if m:
  host = (m.group('host') or '').lower()
  path = (m.group('path') or '')
  scheme = 'ssh'
else:
  p = urlparse(u)
  scheme = (p.scheme or '').lower()
  host = (p.hostname or '').lower()
  path = p.path or ''

  # file://... -> canonical = file:/abs/path
  if scheme == 'file':
    path = (p.path or '').rstrip('/')
    if path.endswith('.git'):
      path = path[:-4]
    print(f"file:{path}")
    sys.exit(0)

# normalize path
path = path.lstrip('/')
path = path.rstrip('/')
if path.endswith('.git'):
  path = path[:-4]

# if we couldn't parse host (rare), fall back to a sanitized string
if not host:
  out = u.rstrip('/')
  if out.endswith('.git'):
    out = out[:-4]
  print(out)
  sys.exit(0)

print(f"{host}/{path}".rstrip('/'))
PY
}

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[git-mirror-backup] DRY-RUN:'
    printf ' %q' "$@"
    echo
    return 0
  fi
  "$@"
}

cleanup_lock() {
  if [[ "$LOCK_HELD" == "true" && -n "$LOCK_DIR" && -d "$LOCK_DIR" ]]; then
    rm -rf "$LOCK_DIR"
  fi
}

acquire_lock() {
  LOCK_DIR="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    if [[ -d "$LOCK_DIR" ]]; then
      fail "lock activo detectado en '$LOCK_DIR' (dry-run sin cambios)"
    fi
    info "DRY-RUN: lock libre en $LOCK_DIR"
    return 0
  fi

  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    if [[ -f "$LOCK_DIR/pid" ]]; then
      fail "otro proceso está ejecutando backup (lock: $LOCK_DIR, pid: $(cat "$LOCK_DIR/pid"))"
    fi
    fail "otro proceso está ejecutando backup (lock: $LOCK_DIR)"
  fi
  echo "$$" > "$LOCK_DIR/pid"
  LOCK_HELD="true"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      require_value "$1" "${2:-}"
      REPO_DIR="${2:-}"
      shift 2
      ;;
    --source-url)
      require_value "$1" "${2:-}"
      SOURCE_URL="${2:-}"
      shift 2
      ;;
    --backup-dir)
      require_value "$1" "${2:-}"
      BACKUP_DIR="${2:-}"
      shift 2
      ;;
    --name)
      require_value "$1" "${2:-}"
      NAME="${2:-}"
      shift 2
      ;;
    --push-url)
      require_value "$1" "${2:-}"
      PUSH_URL="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --allow-push|--i-know-what-im-doing)
      ALLOW_PUSH="true"
      shift
      ;;
    --confirm-push)
      require_value "$1" "${2:-}"
      CONFIRM_PUSH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "opción desconocida: $1 (usa --help)"
      ;;
  esac
done

if [[ -z "$BACKUP_DIR" ]]; then
  BACKUP_DIR="./backups/git-mirror"
fi

[[ "$BACKUP_DIR" != "/" ]] || fail "--backup-dir no puede ser /"
if [[ -e "$BACKUP_DIR" && ! -d "$BACKUP_DIR" ]]; then
  fail "--backup-dir apunta a un archivo, no a un directorio: $BACKUP_DIR"
fi

if [[ -z "$SOURCE_URL" ]]; then
  if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "--source-url no informado y --repo-dir no es un repo git válido"
  fi
  SOURCE_URL="$(git -C "$REPO_DIR" config --get remote.origin.url || true)"
  [[ -n "$SOURCE_URL" ]] || fail "no se encontró remote.origin.url; pasá --source-url"
fi

validate_url "--source-url" "$SOURCE_URL"

if [[ -z "$NAME" ]]; then
  # Toma el último segmento de la URL y quita .git si existe.
  NAME="$(basename "$SOURCE_URL")"
  NAME="${NAME%.git}"
fi

[[ -n "$NAME" ]] || fail "no se pudo resolver el nombre del backup"
[[ "$NAME" =~ ^[A-Za-z0-9._-]+$ ]] || fail "--name inválido. Usar solo [A-Za-z0-9._-]"

if [[ -n "$PUSH_URL" ]]; then
  validate_push_url "$PUSH_URL"
fi

if [[ "$ALLOW_PUSH" == "true" && -z "$PUSH_URL" ]]; then
  fail "--allow-push requiere también --push-url"
fi

if [[ -n "$PUSH_URL" ]]; then
  [[ "$ALLOW_PUSH" == "true" ]] || fail "--push-url está presente pero falta --allow-push"
  [[ "$CONFIRM_PUSH" == "$PUSH_CONFIRM_TOKEN" ]] \
    || fail "--confirm-push inválido. Valor requerido: $PUSH_CONFIRM_TOKEN"

  SOURCE_NORM="$(normalize_repo_id "$SOURCE_URL")"
  PUSH_NORM="$(normalize_repo_id "$PUSH_URL")"
  [[ "$SOURCE_NORM" != "$PUSH_NORM" ]] || fail "--push-url no puede ser igual al origen"
fi

MIRROR_PARENT="${BACKUP_DIR}/${NAME}"
MIRROR_PATH="${MIRROR_PARENT}/${TIMESTAMP}.git"
LOCK_PATH="${BACKUP_DIR}/.${NAME}.mirror.lock"
trap cleanup_lock EXIT INT TERM

info "modo=offline-first dry_run=$DRY_RUN push_habilitado=$ALLOW_PUSH"
info "source_url=$SOURCE_URL"
info "mirror_path=$MIRROR_PATH"

if [[ "$DRY_RUN" == "false" ]]; then
  run_cmd mkdir -p "$BACKUP_DIR"
fi

acquire_lock "$LOCK_PATH"

if [[ -e "$MIRROR_PATH" ]]; then
  fail "destino ya existe (anti-overwrite): $MIRROR_PATH"
fi

run_cmd mkdir -p "$MIRROR_PARENT"
info "clonando espejo bare local"
run_cmd git clone --mirror "$SOURCE_URL" "$MIRROR_PATH"
info "espejo local listo: $MIRROR_PATH"

if [[ -n "$PUSH_URL" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    info "DRY-RUN: se ejecutaría push --mirror hacia $PUSH_URL"
    exit 0
  fi

  if [[ -z "$(git --git-dir "$MIRROR_PATH" for-each-ref --count=1)" ]]; then
    info "sin refs para publicar; se omite push --mirror"
    exit 0
  fi

  info "publicando espejo en $PUSH_URL"
  run_cmd git --git-dir "$MIRROR_PATH" push --mirror "$PUSH_URL"
  info "push --mirror completado"
fi
