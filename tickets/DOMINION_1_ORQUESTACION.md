# DOMINIO 1 (D1) - Orquestación (n8n)

## Objetivo
Estabilizar, auditar y estresar los flujos de trabajo de n8n (`workflow_gamma_blindado.json`, `workflow_alpha.json`). 

## Contexto Operativo
n8n actúa como el pilar de orquestación de tareas en segundo plano. Dado que el Dominio Verde ahora exige que nada interactúe con el entorno host de manera insegura, debemos garantizar que estos flujos respeten las reglas del Sandboxing Efímero (Zero-State) al invocar herramientas, y que logren soportar cargas de operaciones en cadena sin saturar la memoria ni corromper su estado.

## Criterios de Éxito
1. Todos los flujos de n8n pueden ejecutarse y pasar sus scripts de estrés asociados.
2. Los flujos heredan las reglas del "Handoff Verde" si interactúan con herramientas del sistema operativo.
3. Se integran las métricas de éxito en `verify_all.sh` de manera silenciosa pero auditable.
