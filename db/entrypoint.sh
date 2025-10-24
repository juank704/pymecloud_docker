#!/usr/bin/env bash
set -euo pipefail

# Defaults por si alguna env no viene (ajusta a tus valores)
: "${DB_LISTEN_ADDRESSES:=*}"
: "${DB_PORT:=5432}"
: "${DB_MAX_CONNECTIONS:=200}"

: "${DB_SHARED_BUFFERS:=512MB}"
: "${DB_EFFECTIVE_CACHE_SIZE:=1GB}"
: "${DB_MAINTENANCE_WORK_MEM:=256MB}"
: "${DB_WORK_MEM:=16MB}"
: "${DB_EFFECTIVE_IO_CONCURRENCY:=200}"

: "${DB_WAL_LEVEL:=replica}"
: "${DB_WAL_BUFFERS:=16MB}"
: "${DB_CHECKPOINT_TIMEOUT:=5min}"
: "${DB_CHECKPOINT_COMPLETION_TARGET:=0.9}"
: "${DB_MAX_WAL_SIZE:=1GB}"
: "${DB_MIN_WAL_SIZE:=80MB}"

: "${DB_RANDOM_PAGE_COST:=1.1}"

: "${DB_LOGGING_COLLECTOR:=on}"
: "${DB_LOG_DESTINATION:=stderr}"
: "${DB_LOG_FILE_MODE:=0644}"
: "${DB_LOG_LINE_PREFIX:=%m [%p] %q%u@%d }"
: "${DB_LOG_TIMEZONE:=UTC}"

: "${DB_DATESTYLE:=iso, mdy}"
: "${DB_TIMEZONE:=UTC}"
: "${DB_LC_MESSAGES:=C}"
: "${DB_LC_MONETARY:=C}"
: "${DB_LC_NUMERIC:=C}"
: "${DB_LC_TIME:=C}"
: "${DB_DEFAULT_TSEARCH:=pg_catalog.english}"

CONF_DIR=/etc/postgresql
DEST_CONF="$CONF_DIR/postgresql.conf"
mkdir -p "$CONF_DIR"

# Renderizar la plantilla con envsubst
envsubst < /etc/postgresql/postgresql.conf.template > "$DEST_CONF"

# Lanzar Postgres usando ese archivo
exec docker-entrypoint.sh postgres -c "config_file=$DEST_CONF"