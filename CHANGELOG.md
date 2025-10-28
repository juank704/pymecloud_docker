# Historial de Cambios - PymeCloud Docker

## [2025-10-27] - Correcciones para compatibilidad con macOS

### Arreglado
- **start_odoo.sh**: Corregido el método de carga de variables de entorno del archivo `.env` para compatibilidad con macOS
  - Problema: El comando `export $(grep -v '^#' .env | xargs)` fallaba en macOS con configuraciones de PostgreSQL que contenían espacios
  - Solución: Implementado un bucle `while read` que carga solo variables de entorno válidas (formato `VARIABLE=valor`)
  - Archivo modificado: `start_odoo.sh` líneas 12-23

- **odoo/entrypoint.sh**: Añadidos permisos de ejecución
  - Problema: El archivo entrypoint.sh no tenía permisos de ejecución (644), causando error "permission denied"
  - Solución: Cambiados permisos a 755 (ejecutable)
  - El Dockerfile ya incluye `chmod +x` pero se aseguraron los permisos en el archivo fuente

### Notas técnicas
- La nueva implementación filtra solo variables que coinciden con el patrón `^[A-Z_][A-Z0-9_]*=`
- Esto previene errores al intentar exportar configuraciones de PostgreSQL que no son variables de entorno válidas
- Compatible con bash en macOS, Linux y otras plataformas Unix

### Probado en
- macOS (Darwin 24.2.0)
- Docker Desktop para Mac
- Odoo 16.0 con módulos de localización chilena (l10n_cl_fe, l10n_cl_chart_of_account)

## [2025-10-27] - Debug + Modulo para leer RUT

### Arreglado 
- **Debug**: El attach se hace a localhost:5678 (VS Code → Python: Attach using debugpy).
- Recomendado activar solo en entornos de desarrollo (no exponer 5678 públicamente).

- **RUT**: La normalización elimina puntos, homogeneiza mayúsculas y fuerza el prefijo CL.
- Si existe l10n_cl_document_number, el módulo lo respeta; en su ausencia utiliza vat.
- Se agregaron tests unitarios básicos para normalización y DV.

- **Modulos Delete**: Borrar Modulos Copiados Localmente + .gitignore