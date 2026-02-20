# Proyecto Verde V1 — Blindaje UI + Workspaces

**Objetivo:** Garantizar cero movimiento de ventanas entre workspaces, forzar interacción 100% "modo humano" en la UI, y validar el bloqueo de `exec`.

## Fase 1: Workspaces
**Criterio de cierre:** 0 comandos de movimiento de ventanas (`wmctrl -t`, etc.).
- [ ] Eliminar referencias a comandos que mueven ventanas entre workspaces.
- [ ] Asegurar que las aplicaciones abran nativamente en el workspace actual.

## Fase 2: Interacción "Modo Humano"
**Criterio de cierre:** 100% simulación de UI (sin bypass de API).
- [ ] Verificar `scripts/molbot_direct_chat/desktop_ops.py` y `scripts/molbot_direct_chat/web_ask.py`.
- [ ] Asegurar uso de simulación real (tecleo en DOM, clics reales).
- [ ] Eliminar cualquier bypass o inyección directa de estado.

## Fase 3: Seguridad Base
**Criterio de cierre:** `exec` denegado.
- [ ] Confirmar configuración de bloqueo para `exec` y `bash`.
- [ ] Documentar estado actual.

---
**Estado:** En Progreso
**Asignado a:** antigravity
