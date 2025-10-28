#!/usr/bin/env bash
set -euo pipefail

ODOO_CONF=/etc/odoo/odoo.conf
mkdir -p /etc/odoo

DB_HOST="${HOST:-db}"
DB_PORT="${PORT:-5432}"
DB_USER="${POSTGRES_USER:-${ODOO_DB_USER:-odoo}}"
DB_PASSWORD="${POSTGRES_PASSWORD:-${ODOO_DB_PASSWORD:-odoo}}"
DB_NAME="${DB_NAME:-odoo}"
ADMIN_PASS="${ADMIN_PASS:-admin}"
ADDONS_PATH="${ADDONS_PATH:-/mnt/extra-addons}"

cat > "$ODOO_CONF" <<EOF
[options]
admin_passwd = ${ADMIN_PASS}
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${DB_USER}
db_password = ${DB_PASSWORD}
db_name = ${DB_NAME}
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons


gevent_port = 8072
limit_time_poll = 3600
data_dir = /var/lib/odoo/.local/share/Odoo

# Producción ligera
#proxy_mode = True
#workers = 4
#max_cron_threads = 2
#limit_time_cpu = 120
#limit_time_real = 240

# DEBUG MODE
proxy_mode = False
workers = 0
max_cron_threads = 0
limit_time_cpu = 0
limit_time_real = 0


EOF

echo "Generated $ODOO_CONF"

exec python3 -m debugpy --listen 0.0.0.0:5678 /usr/bin/odoo --config "$ODOO_CONF"

# ✅ Ejecuta Odoo directamente (evita recursión)
#exec odoo -c "$ODOO_CONF" "$@"