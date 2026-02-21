# Ticket: CUNNINGHAM_VERDE_V2 — Stress UI y Resiliencia Base

## Objetivo
Garantizar que las pruebas de estrés de la UI usen tecleo realista, asegurar que los servicios systemd tengan auto-recuperación (`Restart=always`) y evitar procesos "zombie" en los scripts de visión mediante rutinas de limpieza estrictas.

## Contexto
Tras cerrar la V1, necesitamos asegurar la robustez del sistema ante carga y fallos inesperados, manteniendo el aislamiento y la seguridad de las reglas estáticas ya implementadas.

## Tareas y Criterios de Aceptación

### 1. Stress UI "100% Humano"
- **Acción:** Refactorizar scripts de estrés para usar tecleo realista.
- **Criterio:** Cero uso de `.fill()` (inyección directa) en inputs de chat. Uso de `delay` en el tecleo.
- **Archivos:** `scripts/ui_stress_test_direct_chat.js`, `scripts/ui_stress_recipes_and_convos.js`.

### 2. Resiliencia Systemd
- **Acción:** Verificar políticas de reinicio en servicios de usuario.
- **Criterio:** `Restart=on-failure` o `Restart=always` configurado y verificado operativamente.
- **Servicios:** `openclaw-direct-chat.service`, `openclaw-gateway.service`.

### 3. Limpieza de Workspaces
- **Acción:** Implementar traps de limpieza en scripts de visión.
- **Criterio:** `trap` funcional que mate procesos hijos al salir (normal o error). Cero ventanas o procesos huérfanos.
- **Archivos:** `scripts/browser_vision.sh`, `scripts/local_vision.sh`.

## Secuencia de Commits
0. `docs: create ticket for Proyecto Verde V2`
1. `test: enforce realistic typing in UI stress scripts`
2. `chore: verify restart policies for isolated services`
3. `refactor: add strict cleanup traps to vision scripts`
