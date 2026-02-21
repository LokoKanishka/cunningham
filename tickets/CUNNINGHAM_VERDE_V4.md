# Ticket: CUNNINGHAM_VERDE_V4 — Autonomía Visual y Workspaces Virtuales

## Objetivo
El bot debe poder "ver" y operar sin secuestrar el monitor físico del usuario, utilizando entornos aislados como Xvfb o Xephyr.

## Tareas y Criterios de Aceptación
1. **Auditoría del Stack de Visión:** Analizar `scripts/browser_vision.sh`, `scripts/local_vision.sh` y `DOCS/AUTONOMY_VISION_STACK.md`.
2. **Implementación de Display Virtual:** Configurar scripts para usar `Xvfb` o `Xephyr` de forma obligatoria o detectada, evitando el Workspace principal del usuario.
3. **Validación de Display:** Asegurar que `$DISPLAY` esté correctamente manejado para evitar colisiones.

## Criterio de Éxito
Pipeline de visión completo sin ventanas visibles en el monitor de trabajo del usuario.

## Sequence
- Commit 0: `docs: create ticket for Proyecto Verde V4`
- Commit 1: `feat(vision): implement display virtualization for autonomy`
