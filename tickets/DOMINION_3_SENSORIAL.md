# DOMINIO 3 (D3) - Integración Sensorial

## Objetivo
Activar y blindar los canales de entrada sensoriales del sistema (`lucy_sensor_client.py` y los contratos `lucy_input`).

## Contexto Operativo
El agente dejará de ser estrictamente reactivo a comandos CLI o chats de texto para comenzar a recibir estímulos del entorno a través de clientes sensoriales. Esta entrada paralela de datos requiere validación estricta para evitar ataques de inyección de prompt o denegación de servicio por exceso de ruido sensorial.

## Criterios de Éxito
1. Auditar `lucy_sensor_client.py` asegurando que corre y transmite al hub adecuado.
2. Validar que la estructura de payload de `lucy_input` cumple con los contratos de limpieza.
3. Permitir que el sistema auto-procese el ruido sin bloquear el pipeline cognitivo principal.
