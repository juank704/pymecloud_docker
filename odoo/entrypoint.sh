#!/usr/bin/env bash
set -euo pipefail

ODOO_CONF=/etc/odoo/odoo.conf
mkdir -p /etc/odoo

# NOTA: evita usar la variable de entorno genérica USER para la DB.
# Usa variables dedicadas (p.ej. ODOO_DB_USER) para no chocar con el usuario del proceso.
DB_HOST="${HOST:-db}"
DB_PORT="${PORT:-5432}"
DB_USER="${POSTGRES_USER:-${ODOO_DB_USER:-odoo}}"
DB_PASSWORD="${POSTGRES_PASSWORD:-${ODOO_DB_PASSWORD:-odoo}}"
DB_NAME="${DB_NAME:-odoo}"
ADMIN_PASS="${ADMIN_PASS:-admin}"
ADDONS_PATH="${ADDONS_PATH:-/opt/baked-addons,/mnt/extra-addons}"

cat > "$ODOO_CONF" <<EOF
[options]
admin_passwd = ${ADMIN_PASS}
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${DB_USER}
db_password = ${DB_PASSWORD}
db_name = ${DB_NAME}
addons_path = /usr/lib/python3/dist-packages/odoo/addons,${ADDONS_PATH}

# Producción ligera
gevent_port = 8072
proxy_mode = True
limit_time_poll = 3600
workers = 4
max_cron_threads = 2
limit_time_cpu = 120
limit_time_real = 240
EOF

echo "Generated $ODOO_CONF"

# ✅ Ejecuta Odoo directamente (evita recursión)
exec odoo -c "$ODOO_CONF" "$@"
# Alternativa si NO montas tu script sobre el entrypoint original:
# exec /usr/bin/entrypoint.sh odoo -c "$ODOO_CONF"