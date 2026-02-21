# Horizonte Verde E1 — Ingeniería del Caos Continua (Chaos Monkey Local)

**Objetivo:** El sistema no solo debe recuperarse de fallos incidentales (V7), sino sobrevivir a ataques destructivos deliberados e internos.

## El Desafío
Diseñar e implementar un daemon (`scripts/chaos_cunningham.sh`) que, de forma aleatoria (durante ventanas de inactividad o bajo configuración), mate procesos críticos (Chromium de Playwright, servidor MCP, nodos de Docker, o el Gateway) y sature puertos temporales para verificar resiliencia.

## Criterio de Éxito
El sistema `total_autoheal.sh` detecta el caos, limpia el desastre, reinicia los componentes aislados en su workspace correcto y documenta el incidente en un log sin que la UI "como humano" colapse o el usuario note una interrupción grave.

---
**Estado:** Abierto
**Fase:** Arquitectura
