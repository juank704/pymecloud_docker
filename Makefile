# =======================
# Variables
# =======================
COMPOSE      = docker compose
SERVICE_APP  = odoo_app
SERVICE_DB   = odoo_db

# Nota: lee variables desde tu .env (recomendado)
# Debes tener ODOO_DB_NAME, POSTGRES_USER, POSTGRES_DB definidos en .env

# =======================
# Helpers
# =======================
.PHONY: up logs down wait-db create-db install-mods upgrade-mods fe-install restart-odoo restart-db backup-now restore psql ping

# Levantar todo y construir imagen
up:
	$(COMPOSE) up -d --build

# Ver logs de Odoo en tiempo real
logs:
	$(COMPOSE) logs -f $(SERVICE_APP)

# Apagar todo
down:
	$(COMPOSE) down

# Esperar a que Postgres esté listo
#wait-db:
#	@echo "Esperando a que Postgres responda..."
#	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc '\
#		until pg_isready -h $$PGHOST -p $${PGPORT:-5432} -U $$POSTGRES_USER >/dev/null 2>&1; do \
#			echo "  - DB no lista aún..."; sleep 2; \
#		done; \
#		echo "DB OK"'

wait-db:
	@echo "Esperando a que Postgres responda..."
	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc '\
		until pg_isready -h 127.0.0.1 -p $${PGPORT:-5432} -U $$POSTGRES_USER >/dev/null 2>&1; do \
			echo "  - DB no lista aún..."; sleep 2; \
		done; \
		echo "DB OK"'

# Crear la base si no existe (usa POSTGRES_DB/ODOO_DB_NAME del entorno)
#create-db: wait-db
#	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc '\
#		DB_NAME=$${ODOO_DB_NAME:-$$POSTGRES_DB}; \
#		echo "Verificando DB $$DB_NAME..."; \
#		EXISTS=$$(psql -U $$POSTGRES_USER -tAc "SELECT 1 FROM pg_database WHERE datname='\''$$DB_NAME'\''"); \
#		if [ "$$EXISTS" = "1" ]; then \
#		  echo "DB $$DB_NAME ya existe."; \
#		else \
#		  echo "Creando DB $$DB_NAME..."; \
#		  createdb -U $$POSTGRES_USER $$DB_NAME; \
#		  echo "DB creada."; \
#		fi'

create-db: wait-db
	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc '\
		DB_NAME=$${ODOO_DB_NAME:-$$POSTGRES_DB}; \
		echo "Verificando DB $$DB_NAME..."; \
		EXISTS=$$(PGPASSWORD=$$POSTGRES_PASSWORD psql -h 127.0.0.1 -p $${PGPORT:-5432} -U $$POSTGRES_USER -tAc "SELECT 1 FROM pg_database WHERE datname='\''$$DB_NAME'\''"); \
		if [ "$$EXISTS" = "1" ]; then \
		  echo "DB $$DB_NAME ya existe."; \
		else \
		  echo "Creando DB $$DB_NAME..."; \
		  PGPASSWORD=$$POSTGRES_PASSWORD createdb -h 127.0.0.1 -p $${PGPORT:-5432} -U $$POSTGRES_USER $$DB_NAME; \
		  echo "DB creada."; \
		fi'

# Instalar módulos por CLI (orden sugerido)
install-mods: create-db
	@$(COMPOSE) exec -T $(SERVICE_APP) bash -lc '\
		DB_NAME=$${ODOO_DB_NAME:-odoo}; \
		echo "Instalando módulos en $$DB_NAME..."; \
		odoo -c /etc/odoo/odoo.conf -d $$DB_NAME -i l10n_cl,l10n_cl_chart_of_account,l10n_cl_fe --stop-after-init'
	$(COMPOSE) restart $(SERVICE_APP)

# Alias más corto para instalación FE
fe-install: install-mods

# Actualizar/upgrade de los módulos (cuando subas versión o cambies código)
upgrade-mods:
	@$(COMPOSE) exec -T $(SERVICE_APP) bash -lc '\
		DB_NAME=$${ODOO_DB_NAME:-odoo}; \
		echo "Actualizando módulos en $$DB_NAME..."; \
		odoo -c /etc/odoo/odoo.conf -d $$DB_NAME -u l10n_cl,l10n_cl_chart_of_account,l10n_cl_fe --stop-after-init'
	$(COMPOSE) restart $(SERVICE_APP)

# Reiniciar servicios
restart-odoo:
	$(COMPOSE) restart $(SERVICE_APP)

restart-db:
	$(COMPOSE) restart $(SERVICE_DB)

# Backup inmediato de la DB
backup-now:
	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc '\
		FILE=/backups/manual_$$(date +%Y-%m-%d_%H-%M).dump; \
		echo "Generando $$FILE ..."; \
		pg_dump -U $$POSTGRES_USER -F c -f $$FILE $${ODOO_DB_NAME:-$$POSTGRES_DB}; \
		echo "Backup listo: $$FILE"'

# Restaurar (ajusta el archivo)
restore:
	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc '\
		FILE=/backups/manual_latest.dump; \
		echo "Restaurando $$FILE ..."; \
		pg_restore -U $$POSTGRES_USER -d $${ODOO_DB_NAME:-$$POSTGRES_DB} $$FILE; \
		echo "Restore listo."'

# Utilidades
psql:
	@$(COMPOSE) exec -it $(SERVICE_DB) bash -lc 'psql -U $$POSTGRES_USER $${ODOO_DB_NAME:-$$POSTGRES_DB}'

ping:
	@$(COMPOSE) exec -T $(SERVICE_DB) bash -lc 'pg_isready -h 127.0.0.1 -p $${PGPORT:-5432} -U $$POSTGRES_USER'
