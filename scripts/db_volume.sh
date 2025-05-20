#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$PROJECT_ROOT")}"
VOLUME_NAME="${COMPOSE_PROJECT_NAME}_postgres_data"
BACKUP_DIR="${PROJECT_ROOT}/backups"

DB_SERVICE=db
WEB_SERVICE=web
DB_USER=user
DB_NAME=apptrackerdb
# ────────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") <cmd> [<args>]

Commands:
  backup [<file>]     Cold backup: stop db, tar volume, start db & web
  restore <file>      Cold restore: stop db, wipe & untar, fix perms, start db & web
  dump                Hot dump: pg_dump → backups/dump_<ts>.sql
  load <file>         Hot load: psql < backups/dump_*.sql

Examples:
  $(basename "$0") backup
  $(basename "$0") restore backups/pgdata_20250520_121314.tar.gz
  $(basename "$0") dump
  $(basename "$0") load backups/dump_20250520_121314.sql
EOF
  exit 1
}

(( $# >= 1 )) || usage
cmd=$1; shift

# ensure backups dir exists
mkdir -p "$BACKUP_DIR"

case "$cmd" in
  backup)
    ts=$(date +%Y%m%d_%H%M%S)
    out="${1:-pgdata_${ts}.tar.gz}"
    [[ $out != /* ]] && out="$BACKUP_DIR/$out"

    echo "⏸️  Stopping '${DB_SERVICE}' service..."
    docker compose stop "$DB_SERVICE"

    echo "📦 Backing up volume '$VOLUME_NAME' → $out"
    docker run --rm \
      -v "${VOLUME_NAME}":/data:ro \
      -v "$BACKUP_DIR":/backup \
      alpine \
      sh -c "tar czf /backup/$(basename "$out") -C /data ."

    echo "🚀 Starting '${DB_SERVICE}' service..."
    docker compose start "$DB_SERVICE"

    echo "🚀 Ensuring '${WEB_SERVICE}' is running..."
    docker compose up -d --no-deps "$WEB_SERVICE"

    echo "✅ Cold backup complete: $out"
    ;;

  restore)
    (( $# == 1 )) || usage
    rel="$1"; infile="$PROJECT_ROOT/$rel"
    [[ -f "$infile" ]] || { echo "❌ Not found: $infile"; exit 2; }

    echo "⏸️  Stopping '${DB_SERVICE}' service..."
    docker compose stop "$DB_SERVICE"

    echo "🗑️  Clearing volume contents..."
    docker run --rm \
      -v "${VOLUME_NAME}":/data \
      alpine \
      sh -c "rm -rf /data/*"

    echo "📥 Restoring '$rel' → volume '$VOLUME_NAME'"
    d="$(dirname "$infile")"; b="$(basename "$infile")"
    docker run --rm \
      -v "${VOLUME_NAME}":/data \
      -v "$d":/backup \
      alpine \
      sh -c "tar xzf /backup/${b} -C /data"

    echo "🔧 Fixing ownership (postgres:postgres)…"
    docker run --rm \
      -v "${VOLUME_NAME}":/data \
      postgres:15 \
      chown -R postgres:postgres /data

    echo "🚀 Starting '${DB_SERVICE}' service..."
    docker compose start "$DB_SERVICE"

    echo "🚀 Ensuring '${WEB_SERVICE}' is running..."
    docker compose up -d --no-deps "$WEB_SERVICE"

    echo "✅ Cold restore complete."
    ;;

  dump)
    ts=$(date +%Y%m%d_%H%M%S)
    fn="dump_${ts}.sql"
    out="$BACKUP_DIR/$fn"

    echo "📝 Hot dump of '${DB_SERVICE}' → $out"
    docker compose exec -T "$DB_SERVICE" \
      pg_dump -U "$DB_USER" -d "$DB_NAME" > "$out"

    echo "✅ Dump complete."
    ;;

  load)
    (( $# == 1 )) || usage
    rel="$1"; infile="$PROJECT_ROOT/$rel"
    [[ -f "$infile" ]] || { echo "❌ Not found: $infile"; exit 2; }

    echo "↩️  Hot load into '${DB_SERVICE}' from '$rel'"
    cat "$infile" | docker compose exec -T "$DB_SERVICE" \
      psql -U "$DB_USER" -d "$DB_NAME"

    echo "✅ Load complete."
    ;;

  *)
    usage
    ;;
esac

echo "✅ Done."
