# Ticket: CUNNINGHAM_VERDE_V3 — Aislamiento de Display y Lectura Realista

## Objetivo
Garantizar validación estricta de la variable `$DISPLAY`, forzar lectura de respuestas de chat exclusivamente vía DOM (cero lecturas de estado interno o red), y asegurar higiene de logs en los tests de UI.

## Contexto
Este es el último candado del Proyecto Verde. Aseguramos que el bot no solo actúe como humano al enviar datos (V2), sino que también lo haga al recibirlos, manteniendo un aislamiento total del entorno visual.

## Tareas y Criterios de Aceptación

### 1. Fail-Fast de Display
- **Acción:** Agregar validación de `$DISPLAY` / `$WAYLAND_DISPLAY` en scripts de UI.
- **Criterio:** El script debe fallar inmediatamente si no hay un entorno gráfico definido.
- **Archivos:** `scripts/browser_vision.sh`, `scripts/ui_open.sh` (si existe), y otros scripts de automatización visual.

### 2. Lectura UI Realista
- **Acción:** Asegurar que la lectura de respuestas del asistente sea vía DOM.
- **Criterio:** Cero interceptación de red (XHR/Fetch) o acceso a DB interna para leer la respuesta del chat.
- **Archivos:** `scripts/molbot_direct_chat/web_ask.py`, `scripts/ui_stress_*.js`.

### 3. Higiene de Logs
- **Acción:** Sanitizar la salida de consola de los tests.
- **Criterio:** No debe haber tokens, cookies o volcados masivos de HTML sensible en los logs de tests fallidos.

## Secuencia de Commits
0. `docs: create ticket for Proyecto Verde V3`
1. `feat: add fail-fast display validation to UI scripts`
2. `refactor: enforce DOM-only response reading in UI scripts`
3. `chore: sanitize UI test console logs`
