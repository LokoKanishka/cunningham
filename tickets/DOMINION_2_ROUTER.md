# DOMINIO 2 (D2) - Router de Modelos

## Objetivo
Unificar y robustecer la capacidad del sistema para conmutar dinámicamente entre distintos Modelos de Lenguaje (LLMs) usando `model_router.sh`, `model_max.sh`, y validar esta conmutación usando `verify_dc_models.sh`.

## Contexto Operativo
El laboratorio cuenta con acceso tanto a modelos de frontera (Cloud) como a modelos locales, además de configuraciones de "esfuerzo máximo" (`model_max`). Es vital que el ruteo sea inteligente, predecible y no rompa el contexto de las herramientas (como el vision-assert o los sandboxes).

## Criterios de Éxito
1. Refactorizar/auditar `model_router.sh` para asegurar que el ruteo es seguro y rápido.
2. `verify_dc_models.sh` debe ejecutar un barrido garantizando que todos los conectores responden correctamente al prompt de saludo.
3. Los cambios de modelo no deben corromper el gateway del OpenClaw ni el Direct Chat subyacente.
