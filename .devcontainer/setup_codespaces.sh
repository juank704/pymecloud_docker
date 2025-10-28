#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setup Odoo + Chile en Codespaces"

# === Cargar .env (solo pares VAR=valor válidos) ===
ENV_FILE="/workspaces/${localWorkspaceFolderBasename:-pymecloud_docker}/.env"
if [ -f "$ENV_FILE" ]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
      export "$line"
    fi
  done < "$ENV_FILE"
else
  echo "⚠️ No se encontró .env en $ENV_FILE (usando defaults)"
fi

# Defaults por si faltan en .env
ODOO_DB_HOST="${ODOO_DB_HOST:-db}"
ODOO_DB_PORT="${ODOO_DB_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-odoo}"
POSTGRES_USER="${POSTGRES_USER:-odoo}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-odoo}"

echo "🔧 Variables:"
echo "  ODOO_DB_HOST=$ODOO_DB_HOST"
echo "  ODOO_DB_PORT=$ODOO_DB_PORT"
echo "  POSTGRES_DB=$POSTGRES_DB"
echo "  POSTGRES_USER=$POSTGRES_USER"

# === Esperar DB (desde el contenedor odoo, sin docker compose) ===
echo "⏳ Esperando a que la DB esté lista..."
until pg_isready -h "$ODOO_DB_HOST" -p "$ODOO_DB_PORT" -U "$POSTGRES_USER" >/dev/null 2>&1; do
  echo "   - DB aún no responde, reintentando..."
  sleep 3
done
echo "✅ DB OK"

# === Copiar baked-addons → extra-addons (no sobrescribir, sin chown) ===
if [ -d /opt/baked-addons ]; then
  echo "📦 Copiando /opt/baked-addons → /mnt/extra-addons (sin sobrescribir)..."
  cp -rn /opt/baked-addons/* /mnt/extra-addons/ 2>/dev/null || true
fi

# === Instalar / actualizar módulos por CLI (dentro del contenedor) ===
# Usa ODOO_INIT=1 para forzar instalación (-i) en una DB nueva.
MODULES="l10n_cl,l10n_cl_chart_of_account,l10n_cl_fe,custom_disable_cl_vat"
if [ "${ODOO_INIT:-0}" = "1" ]; then
  ACTION="-i $MODULES"
  echo "🧩 Inicializando módulos: $MODULES"
else
  ACTION="-u $MODULES"
  echo "🧩 Actualizando módulos: $MODULES"
fi

set +e
odoo \
  --db_host="$ODOO_DB_HOST" \
  --db_port="$ODOO_DB_PORT" \
  --db_user="$POSTGRES_USER" \
  --db_password="$POSTGRES_PASSWORD" \
  -d "$POSTGRES_DB" \
  $ACTION \
  --load-language=es_CL \
  --without-demo=none \
  --stop-after-init \
  --http-port=8070
rc=$?
set -e

if [ $rc -ne 0 ]; then
  echo "❌ Error inicializando/actualizando módulos (rc=$rc)."
  echo "   - Si la DB es nueva, reintenta con: ODOO_INIT=1"
  exit $rc
fi

echo "🎉 Setup listo. Abre Odoo en el puerto 8069."
echo "💡 En Codespaces, marca el puerto 8069 como Public en la pestaña Ports."