#!/bin/bash
set -e
set -o pipefail

# ==============================================
#  Odoo + CL - Instalación automática (Linux)
# ==============================================

echo "🚀 Iniciando instalación automática de Odoo + Chile..."
echo

# === Cargar variables del archivo .env ===
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ No se encontró el archivo .env en el directorio actual."
    exit 1
fi

# === Mostrar variables cargadas ===
echo "ODOO_VERSION=$ODOO_VERSION"
echo "POSTGRES_VERSION=$POSTGRES_VERSION"
echo "POSTGRES_DB=$POSTGRES_DB"
echo "POSTGRES_USER=$POSTGRES_USER"
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
echo "ODOO_ADMIN_PASS=$ODOO_ADMIN_PASS"
echo "ODOO_DB_HOST=$ODOO_DB_HOST"
echo "ODOO_DB_PORT=$ODOO_DB_PORT"
echo

# ===================================================
# 1) Verificar si "make" está instalado
# ===================================================
if ! command -v make &> /dev/null; then
    echo "⚠️  'make' no está instalado en tu sistema."
    exit 1
fi

# ===================================================
# 2) Variables principales
# ===================================================
APP_SVC="odoo"
DB_SVC="db"
DB_CTN="odoo_db"
ODOO_DB_NAME="odoo"

echo "🚀 Levantando y construyendo contenedores..."
make up || { echo "❌ Error al construir contenedores."; exit 1; }

# ===================================================
# 3) Esperar a que la DB esté healthy
# ===================================================
echo "⏳ Esperando a que la DB esté lista (healthy)..."

until docker compose exec -T "$DB_SVC" pg_isready -h 127.0.0.1 -p "$ODOO_DB_PORT" -U "$POSTGRES_USER" > /dev/null 2>&1; do
    echo "   - DB aún no responde, reintentando..."
    sleep 3
done
echo "✅ DB OK"

# ===================================================
# 4) Crear esquema y módulos Odoo por CLI
# ===================================================
echo "🧩 Deteniendo Odoo para inicializar base de datos..."
docker compose stop "$APP_SVC" >/dev/null 2>&1 || true

echo "📦 Instalando módulos Odoo con demo data..."
docker compose run --rm --no-deps --entrypoint odoo odoo \
  --db_host="$ODOO_DB_HOST" \
  --db_port="$ODOO_DB_PORT" \
  --db_user="$POSTGRES_USER" \
  --db_password="$POSTGRES_PASSWORD" \
  -d "$POSTGRES_DB" \
  -i base,l10n_cl,l10n_cl_chart_of_account,l10n_cl_fe \
  --load-language=es_CL \
  --without-demo=none \
  --stop-after-init \
  --http-port=8070 || {
      echo "❌ Error inicializando la base de datos de Odoo."
      exit 1
  }

echo "✅ Esquemas creados correctamente."

# ===================================================
# 5) Reiniciar Odoo normalmente
# ===================================================
echo "🔄 Reiniciando servicio Odoo..."
docker compose up -d "$APP_SVC"

# ===================================================
# 6) Mostrar logs y abrir navegador
# ===================================================
echo "🔭 Mostrando logs (Ctrl+C para salir)..."
docker compose logs -f "$APP_SVC" &
sleep 3

URL="http://localhost:8069"
echo "🌐 Abriendo Odoo en $URL"
if command -v xdg-open &> /dev/null; then
    xdg-open "$URL" >/dev/null 2>&1 || true
fi

echo "✅ Todo listo. Odoo ejecutándose."