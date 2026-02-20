# Horizonte Verde E3 — Assertions de UI Basadas en Visión

**Objetivo:** Validar la Interfaz de Usuario "como humano", usando los *ojos* de un humano.

## El Desafío
Actualmente en la V3 confiamos en leer el DOM (Playwright `textContent`) para asegurar que el chat responde. Pero un humano no lee el DOM, lee píxeles. Integrar los modelos locales de visión (del stack autonómico) para tomar capturas de pantalla del display virtual (`Xvfb`) y usar OCR/Visión para validar que el texto realmente se *renderizó* en la pantalla y es legible, y que no hay elementos superpuestos o UI rota.

## Criterio de Éxito
Los tests de estrés y las comprobaciones de estado visualizan el render de Molbot Direct Chat y afirman su integridad gráfica y semántica, de manera 100% offline y aislada. Si el DOM es correcto pero visualmente el chat está corrupto, la prueba falla.

---
**Estado:** Abierto
**Fase:** Planificación
