# cunningham

Laboratorio desde cero para Moltbot upstream + modelos externos + cambio de modelo + extensiones comunitarias (con trazabilidad y seguridad).

## Documentación clave
- `PLAN.md` — objetivo, reglas, roadmap
- `docs/SECURITY_CHECKLIST.md` — checklist para integrar comunidad
- `docs/INTEGRATIONS.md` — registro de integraciones pinneadas
- `DOCS/ALLTALK_DOCKER.md` — voz neural por Docker (AllTalk)

## Operación rápida
- Botón rojo: `./scripts/verify_all.sh`
- Modo amplio (más capacidad de tools): `./scripts/mode_full.sh`
- Modo seguro (allowlist reducida): `./scripts/mode_safe.sh`
- Backup espejo Git: `./scripts/git_mirror_backup.sh --help`
- UI local opcional del stack (Dockge): `docs/INTERFAZ_STACK_DOCKGE.md`
- UI funcional del Gateway (Lucy Panel): `docs/LUCY_UI_PANEL.md`

## Backup espejo Git (offline-first y seguro)
- Modo por defecto: `offline-only`.
- Cada ejecución crea un mirror bare nuevo en: `./backups/git-mirror/<name>/<YYYYmmdd_HHMMSS_mmm>.git`.
- Anti-overwrite: si el destino ya existe, falla.
- Concurrencia: usa lockfile para evitar ejecuciones simultáneas.
- `--dry-run`: no crea archivos ni hace push; solo imprime el plan.
- `--push-url` está bloqueado por defecto. Para habilitar push se requieren dos flags:
  - `--allow-push`
  - `--confirm-push YES_PUSH_MIRROR`

Ejemplos seguros:

```bash
# Ver plan sin tocar disco/remotos
./scripts/git_mirror_backup.sh --dry-run

# Crear solo mirror local (recomendado)
./scripts/git_mirror_backup.sh

# Push espejo explícito (peligroso si destino equivocado)
./scripts/git_mirror_backup.sh \
  --push-url https://github.com/tu-user/tu-repo-espejo.git \
  --allow-push \
  --confirm-push YES_PUSH_MIRROR
```

Guardrails:
- Nunca uses `--push-url` apuntando al repo origen.
- Evitá incluir tokens en URLs; preferí credenciales del helper de Git/SSH.
- Revisá siempre `--dry-run` antes de habilitar push.
- Modo “sin pagar / sin tokens / sin push involuntario”: usá solo mirror local (sin `--push-url`) y, si querés 100% local, `--source-url /ruta/al/repo/.git`.

## Stack autonomía+visión (10)
- Documento: `DOCS/AUTONOMY_VISION_STACK.md`
- Verificación del stack: `./scripts/verify_stack10.sh`
- Botón rojo base (estable): `./scripts/verify_all.sh`

## Stack autonomía+visión (next 10)
- Documento: `DOCS/AUTONOMY_VISION_STACK_NEXT10.md`
- Verificación: `./scripts/verify_next10.sh`
- Extras: `./scripts/goals_worker.sh check`, `./scripts/ops_alerts.sh check`, `./scripts/web_research.sh check`

## Comunidad GitHub (20 descargas, pinneadas)
- Catálogo: `DOCS/community_mcp_catalog.json`
- Guía: `DOCS/COMMUNITY_MCP.md`
- Validar: `./scripts/community_mcp.sh check`
- Descargar bundle comunitario: `./scripts/community_mcp.sh sync`
- Bridge MCP top10 (mcporter): `./scripts/community_mcp_bridge.sh setup`
- Verificar bridge: `./scripts/community_mcp_bridge.sh check`
- Probar 10/10: `./scripts/community_mcp_bridge.sh probe`

## UX (Consola + Español + Voz)
- Consola pro: `./scripts/console_pro.sh`
- Modo español persistente: `./scripts/set_spanish_mode.sh`
- Chat con salida por voz: `./scripts/chat_voice_es.sh "tu pregunta"`
- Doc: `DOCS/UX_SPANISH_VOICE.md`

<!-- DC_OPS_SECURITY_BEGIN -->
## Direct Chat: Ops & Security

### systemd (no más choques de puerto)
Direct Chat corre como servicios de usuario:

- `openclaw-direct-chat.service`
- `openclaw-gateway.service`

Comandos útiles:

```bash
systemctl --user status openclaw-direct-chat.service --no-pager
systemctl --user status openclaw-gateway.service --no-pager
systemctl --user restart openclaw-direct-chat.service openclaw-gateway.service
journalctl --user -u openclaw-direct-chat.service -n 200 --no-pager
journalctl --user -u openclaw-gateway.service -n 200 --no-pager
```

### seguridad (exec deshabilitado por defecto)

Para evitar que el modelo ejecute comandos arbitrarios, `exec` queda denegado por defecto
en `~/.openclaw/openclaw.json` (deny: `exec`, `bash`; allow: sin `exec`).
<!-- DC_OPS_SECURITY_END -->
