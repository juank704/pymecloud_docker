FROM postgres:16

RUN apt-get update \
 && apt-get install -y --no-install-recommends locales \
 && sed -i 's/^# *\(es_CL.UTF-8\)/\1/' /etc/locale.gen \
 && sed -i 's/^# *\(es_ES.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# (Opcional) defaults de entorno
ENV LANG=es_CL.UTF-8 LC_ALL=es_CL.UTF-8