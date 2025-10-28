@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Odoo + CL - Instalación automática
chcp 65001 >nul

REM === Cargar variables del archivo .env ===
for /f "usebackq tokens=1,2 delims==" %%A in (".env") do (
    set "key=%%A"
    set "value=%%B"
    REM Ignorar líneas vacías y comentarios
    if not "!key!"=="" if "!key:~0,1!" NEQ "#" set "!key!=!value!"
)

REM === Mostrar las variables cargadas (opcional) ===
echo ODOO_VERSION=%ODOO_VERSION%
echo POSTGRES_VERSION=%POSTGRES_VERSION%
echo POSTGRES_DB=%POSTGRES_DB%
echo POSTGRES_USER=%POSTGRES_USER%
echo POSTGRES_PASSWORD=%POSTGRES_PASSWORD%
echo ODOO_ADMIN_PASS=%ODOO_ADMIN_PASS%
echo ODOO_DB_HOST=%ODOO_DB_HOST%
echo ODOO_DB_PORT=%ODOO_DB_PORT%

REM ===================================================
REM 1) Verificar si "make" está instalado
REM ===================================================
where make >nul 2>nul
if errorlevel 1 (
    echo ⚠️  'make' no está instalado en tu sistema.
    exit /b
)

REM ===================================================
REM 2) Variables principales
REM  - DB_SVC es el NOMBRE DEL SERVICIO en docker-compose (p.ej. "db")
REM  - DB_CTN es el nombre del contenedor (si usas container_name: odoo_db)
REM  - APP_SVC es el servicio de Odoo (p.ej. "odoo")
REM ===================================================
set APP_SVC=odoo
set DB_SVC=db
set DB_CTN=odoo_db
set ODOO_DB_NAME=odoo

echo.
echo 🚀 Levantando y construyendo contenedores...
make up
if errorlevel 1 exit /b 1

REM ===================================================
REM 3) Esperar a que la DB esté healthy
REM    Primero intentamos "docker compose wait db" (servicio).
REM    Si no existe o no está soportado, usamos fallback por inspect.
REM ===================================================
echo ⏳ Esperando a que la DB esté lista (healthy)...
:waitdb

docker compose exec -T %DB_SVC% pg_isready -h 127.0.0.1 -p %ODOO_DB_PORT% -U %POSTGRES_USER% >nul 2>&1
if errorlevel 1 (
  echo   - DB aun no responde, reintentando...
  timeout /t 3 >nul
  goto :waitdb
)
echo ✅ DB OK

REM --Copiar Archivos Baked_Addons to Extra_Addons
docker compose exec odoo bash -lc "cp -rn /opt/baked-addons/* /mnt/extra-addons/"

REM ===================================================
REM 4) Crear esquema y módulos Odoo por CLI
REM ===================================================

REM Odoo apagado para que no choque el puerto 8069
docker compose stop odoo
docker compose stop %APP_SVC%

REM --- Instalar módulos por CLI (Opción A: forzar credenciales y puerto temporal) ---
docker compose run --rm --no-deps --entrypoint odoo odoo ^
  --db_host=%ODOO_DB_HOST% ^
  --db_port=%ODOO_DB_PORT% ^
  --db_user=%POSTGRES_USER% ^
  --db_password=%POSTGRES_PASSWORD% ^
  -d %POSTGRES_DB% ^
  -i base,l10n_cl,l10n_cl_chart_of_account,l10n_cl_fe,custom_disable_cl_vat ^
  --load-language=es_CL --without-demo=none --stop-after-init --http-port=8070

if errorlevel 1 (
  echo ❌ Error inicializando la base de datos de Odoo.
  pause
  exit /b 1
)

echo ▶️  Levantando Odoo...
docker compose up -d %APP_SVC%

echo ✅ Esquemas creados correctamente.

REM ===================================================
REM 5) Reiniciar Odoo normalmente
REM ===================================================
echo 🔄 Reiniciando servicio Odoo...
docker compose restart %APP_SVC%

echo 🔄 Recreating nginx
docker compose up -d --force-recreate nginx

REM ===================================================
REM 6) Mostrar logs y abrir navegador
REM ===================================================
echo 🔭 Mostrando logs (se abre otra ventana)...
start cmd /k "docker compose logs -f %APP_SVC%"

echo 🌐 Abriendo Odoo en http://localhost
start http://localhost


echo ✅ Todo listo. Odoo ejecutándose.
pause