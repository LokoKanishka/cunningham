#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="."
SOURCE_URL=""
BACKUP_DIR=""
NAME=""
PUSH_URL=""

usage() {
  cat <<'EOF'
Uso:
  ./scripts/git_mirror_backup.sh [opciones]

Opciones:
  --repo-dir <path>     Repo local para detectar origin (default: .)
  --source-url <url>    URL origen (si no se pasa, usa remote.origin.url)
  --backup-dir <path>   Directorio base de backups (default: ./backups/git-mirror)
  --name <nombre>       Nombre del espejo (default: nombre del repo origen)
  --push-url <url>      Si se pasa, hace git push --mirror a este remoto
  -h, --help            Muestra esta ayuda

Ejemplos:
  ./scripts/git_mirror_backup.sh
  ./scripts/git_mirror_backup.sh --source-url https://github.com/org/repo.git --name backup-cunningham
  ./scripts/git_mirror_backup.sh --push-url https://github.com/tu-user/repo-espejo.git
EOF
}

fail() {
  echo "[git-mirror-backup] ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      REPO_DIR="${2:-}"
      shift 2
      ;;
    --source-url)
      SOURCE_URL="${2:-}"
      shift 2
      ;;
    --backup-dir)
      BACKUP_DIR="${2:-}"
      shift 2
      ;;
    --name)
      NAME="${2:-}"
      shift 2
      ;;
    --push-url)
      PUSH_URL="${2:-}"
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

if [[ -z "$SOURCE_URL" ]]; then
  if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "--source-url no informado y --repo-dir no es un repo git válido"
  fi
  SOURCE_URL="$(git -C "$REPO_DIR" config --get remote.origin.url || true)"
  [[ -n "$SOURCE_URL" ]] || fail "no se encontró remote.origin.url; pasá --source-url"
fi

if [[ -z "$NAME" ]]; then
  # Toma el último segmento de la URL y quita .git si existe.
  NAME="$(basename "$SOURCE_URL")"
  NAME="${NAME%.git}"
fi

[[ -n "$NAME" ]] || fail "no se pudo resolver el nombre del backup"

MIRROR_PATH="${BACKUP_DIR}/${NAME}.git"
mkdir -p "$BACKUP_DIR"

if [[ -d "$MIRROR_PATH" ]]; then
  if [[ ! -f "$MIRROR_PATH/HEAD" ]]; then
    fail "ya existe '$MIRROR_PATH' pero no parece un repo bare"
  fi
  echo "[git-mirror-backup] actualizando espejo en $MIRROR_PATH"
  git --git-dir "$MIRROR_PATH" remote set-url origin "$SOURCE_URL"
  git --git-dir "$MIRROR_PATH" fetch --all --prune --tags
else
  echo "[git-mirror-backup] clonando espejo desde $SOURCE_URL"
  git clone --mirror "$SOURCE_URL" "$MIRROR_PATH"
fi

echo "[git-mirror-backup] espejo listo: $MIRROR_PATH"

if [[ -n "$PUSH_URL" ]]; then
  HAS_REFS="$(git --git-dir "$MIRROR_PATH" for-each-ref --count=1 | wc -l | tr -d ' ')"
  if [[ "$HAS_REFS" == "0" ]]; then
    echo "[git-mirror-backup] sin refs para publicar; se omite push --mirror"
    exit 0
  fi
  echo "[git-mirror-backup] publicando espejo en $PUSH_URL"
  git --git-dir "$MIRROR_PATH" push --mirror "$PUSH_URL"
  echo "[git-mirror-backup] push --mirror completado"
fi
