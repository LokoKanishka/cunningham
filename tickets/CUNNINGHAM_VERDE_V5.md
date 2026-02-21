# Ticket: CUNNINGHAM_VERDE_V5 — Blindaje de MCP y Comunidad (Sandboxing)

## Objetivo
Garantizar que las extensiones externas (MCP) operen en un entorno de "confianza cero".

## Tareas y Criterios de Aceptación
1. **Auditoría MCP:** Revisar `scripts/community_mcp.sh`, `scripts/community_mcp_bridge.sh` y catalogos.
2. **Hardening de Ejecución:** Restringir llamadas a shell y asegurar herencia de bloqueos de seguridad (`exec`, `bash`).

## Criterio de Éxito
Las herramientas comunitarias maliciosas fallan inmediatamente al intentar invocar shells locales.

## Sequence
- Commit 0: `docs: create ticket for Proyecto Verde V5`
- Commit 1: `security(mcp): harden community tool sandboxing`
