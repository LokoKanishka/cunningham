# Plugins — política y allowlist

## Principio
- Solo se permite **lo que está en allowlist**.
- Cualquier plugin fuera de allowlist **no puede estar loaded**.
- Cambios de plugins requieren reinicio de gateway para aplicar.

## Allowlist (fuente de verdad)
Ver: `DOCS/allowlist_plugins.txt`

## Reglas adicionales
- `lobster` debe estar **loaded** (workflows con aprobaciones).
- WhatsApp debe estar **OFF** (canal deshabilitado), independientemente de si el plugin está instalado.
