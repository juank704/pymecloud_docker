FROM odoo:16.0
USER root

# Instala debugpy (y cualquier lib de desarrollo que uses)
RUN pip3 install --no-cache-dir debugpy

# ---------- Paquetes del sistema ----------
# + git/locales para clonar y es_CL.UTF-8
# + toolchain/libs para compilar e integrar libs crypto/XML
# + libs de imagenes (Pillow) y (opcional) OCR (tesseract)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      git locales \
      build-essential libxml2-dev libxslt1-dev libffi-dev libssl-dev \
      libjpeg62-turbo zlib1g libtiff5 libopenjp2-7 libfreetype6 liblcms2-2 \
      tesseract-ocr tesseract-ocr-spa \
    && rm -rf /var/lib/apt/lists/*

# ---------- Locales Chile ----------
RUN sed -i 's/# *es_CL.UTF-8 UTF-8/es_CL.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=es_CL.UTF-8 LC_ALL=es_CL.UTF-8 LANGUAGE=es_CL:es

# ---------- Rutas de addons ----------
ENV ODOO_BAKED_ADDONS=/opt/baked-addons
RUN mkdir -p ${ODOO_BAKED_ADDONS}

# ---------- Clonar addons ----------
RUN set -eux \
 && git clone --depth 1 -b 16.0 https://gitlab.com/dansanti/l10n_cl_fe.git ${ODOO_BAKED_ADDONS}/l10n_cl_fe \
 && git clone --depth 1 -b 16.0 https://gitlab.com/odoocoop-spa/l10n_cl_chart_of_account.git ${ODOO_BAKED_ADDONS}/l10n_cl_chart_of_account \
 && chown -R odoo:odoo ${ODOO_BAKED_ADDONS}

# ---------- Congelar dependencias Python ----------
# Copiamos pines de versión e instalamos con pip
COPY requirements-locked.txt /tmp/requirements-locked.txt
RUN set -eux; \
    python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
    python3 -m pip install --no-cache-dir -r /tmp/requirements-locked.txt

# (Opcional) instalar requirements propios de los repos si existen
RUN set -eux; \
    for repo in l10n_cl_fe l10n_cl_chart_of_account; do \
        REQ="${ODOO_BAKED_ADDONS}/${repo}/requirements.txt"; \
        if [ -f "$REQ" ]; then \
            echo "Instalando requirements de $repo..."; \
            python3 -m pip install --no-cache-dir -r "$REQ"; \
        else \
            echo "Sin requirements.txt en $repo (omitido)"; \
        fi; \
    done

# (Opcional) Hornear tu entrypoint propio
COPY entrypoint.sh /usr/local/bin/odoo-entrypoint.sh
RUN chmod +x /usr/local/bin/odoo-entrypoint.sh
# Si quieres usar SIEMPRE tu entrypoint horneado, descomenta:
# ENTRYPOINT ["/usr/local/bin/odoo-entrypoint.sh"]

USER odoo
EXPOSE 8069 8072 5678