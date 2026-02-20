# Contrato Arquitectónico: Dominio Verde (Gold Master)

**Estado:** ACTIVO | **Autoridad:** Cunningham V (Arquitecto / Centinela)

Este documento representa el manifiesto fundacional y el testamento de seguridad del **Dominio Verde**. Cualquier agente, modelo o humano que interactúe con el código de este repositorio **DEBE** adherirse estrictamente a estas leyes innegociables. La suite de CI (`scripts/verify_all.sh`) hará cumplir estas reglas implacablemente.

## 1. Aislamiento Físico y de Workspace (Zero-Interference)
- **Regla:** Está estrictamente prohibido que cualquier script de automatización mueva ventanas, cambie de escritorio virtual o robe el foco del usuario.
- **Implementación:** Todas las interacciones de UI (navegadores, chatbots) deben ocurrir en "Displays Aislados" (virtualizados vía `Xvfb` u ocultos en Chromium headless) utilizando `scripts/display_isolation.sh`.
- **Justificación:** El usuario maestro nunca debe ser interrumpido por la maquinaria.

## 2. Emulación UI 100% "Modo Humano"
- **Regla:** Las interacciones del bot con cualquier interfaz web deben ser indistinguibles de las de un humano. No se permiten inyecciones directas en el DOM (ej. cambiar valores de `input` mutando variables de JS) ni bypasses de API si el objetivo es operar la UI.
- **Implementación:** El bot debe hacer clic físico y tipear de forma natural usando utilidades como el `typeHuman` de Playwright o capas de simulación de `xdotool`.

## 3. Bloqueo Absoluto de Ejecución Directa (`exec`/`bash`)
- **Regla:** Ningún LLM o agente tiene permitido generar o inyectar comandos brutos de `bash`, `exec`, o análogos directamente en el host para ejecutar código arbitrario generado dinámicamente. Todo debe pasar por interfaces AST blindadas.
- **Implementación:** Funciones peligrosas purgadas auditablemente (`scripts/verify_exec_drift.sh`).

## 4. Sandboxing MCP Efímero y Desechable (Zero-State)
- **Regla:** Toda comunicación y ejecución de herramientas de la comunidad (Community MCPs mediante `npx`, `uvx`, etc.) se realizará bajo el paradigma "Zero-State" (Confianza Cero).
- **Implementación:** Se utiliza `bubblewrap` (`scripts/mcp_sandbox_wrapper.sh`), asegurando que el proceso nazca y muera íntegramente en la memoria RAM (montajes `tmpfs`). El proceso externo no tiene acceso a archivos sensibles del host (`~/.ssh`, directorio real, etc.). Si el kernel restringe esta ejecución segura, el sistema debe fallar ruidosamente (Fail-Fast) antes que abortar la seguridad y comprometer el entorno en silencio.

## 5. Validación de la Realidad mediante OCR (Assertions por Visión)
- **Regla:** Las pruebas end-to-end (E2E) no deben confiar ciegamente en el árbol DOM, ya que este puede ocultar ilusiones de CSS y elementos superpuestos que rompen la usabilidad.
- **Implementación:** El sistema debe tomar capturas de pantalla de los displays virtuales (`Xvfb`) y usar reconocimiento óptico de caracteres (OCR mediante Tesseract en `scripts/local_vision.sh`) para confirmar matemáticamente que los píxeles renderizados son legibles como se espera (`scripts/ui_vision_assert.sh`).

## 6. Autosanación Total y Caos Proactivo
- **Regla:** La infraestructura debe auto-curarse ante caídas inevitables.
- **Implementación:** Monitoreado y reiniciado constantemente por `scripts/total_autoheal.sh`, y probado en combate continuo por nuestro "Chaos Monkey" local en cron (`scripts/chaos_cunningham.sh`).

---
> "Si el bot de test te grita, es porque violaste el Dominio Verde. Rectifica o abstente de tocar este código."
> — *El Centinela Durmiente*
