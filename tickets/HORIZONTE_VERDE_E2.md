# Horizonte Verde E2 — Sandboxing Efímero y Desechable (Zero-State MCP)

**Objetivo:** Llevar el sandboxing de `bubblewrap` (V5) al extremo paranoico. Los entornos de ejecución de herramientas externas deben nacer y morir con cada solicitud.

## El Desafío
Las herramientas comunitarias no solo no deben acceder a archivos sensibles, sino que no deben dejar rastro persistente en el sistema operativo host. Diseñar un mecanismo donde los puentes MCP (`community_mcp_bridge.sh`) levanten un rootfs o entorno temporal y efímero en memoria (`tmpfs`) para ejecutar la herramienta. Una vez devuelto el output, el entorno se destruye a nivel de kernel, eliminando cualquier archivo cache, temporal o payload descargado.

## Criterio de Éxito
Cero persistencia de estado para cualquier herramienta de terceros. Una herramienta maliciosa que intente descargar un payload o minar crypto pierde su entorno en milisegundos tras finalizar su tarea principal.

---
**Estado:** Abierto
**Fase:** Planificación
