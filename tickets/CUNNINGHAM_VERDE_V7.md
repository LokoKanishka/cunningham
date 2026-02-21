# Ticket: CUNNINGHAM_VERDE_V7 (FINAL) — Daemonización y Autosanación Total

## Objetivo
Operación autónoma, resiliente y autosanable en background.

## Tareas y Criterios de Aceptación
1. **Auditoría de Ops:** Revisar scripts de alertas y observación.
2. **Auto-reparación UI:** Reinicio automático ante fallos de Playwright o procesos huérfanos.

## Criterio de Éxito
Superación de `verify_all.sh` con recuperación automática tras inyección de fallos manuales.

## Sequence
- Commit 0: `docs: create ticket for Proyecto Verde V7`
- Commit 1: `ops: implement global self-healing and total daemonization`
