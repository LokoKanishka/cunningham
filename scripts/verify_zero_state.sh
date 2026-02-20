#!/usr/bin/env bash
set -euo pipefail

# verify_zero_state.sh — Verifica que el sandbox MCP funciona y elimina rastros (Horizonte Verde E2)

echo "[test] Verificando Zero-State MCP Sandbox..."

if [ "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null)" = "1" ]; then
  echo "SKIP: AppArmor restringe los user namespaces no privilegiados."
  echo "      No se puede iniciar bubblewrap."
  echo "      Por favor, corra: sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0"
  exit 0
fi

# 1. Probar ejecución y sistema de archivos efímero
echo "[test] Corriendo MCP Sandbox test payload..."
PAYLOAD_DIR="$HOME/.cache"

out=$(./scripts/mcp_sandbox_wrapper.sh sh -c 'echo "zero-state" > ~/.cache/vuln.txt && cat ~/.cache/vuln.txt')
if [ "$out" != "zero-state" ]; then
  echo "ERROR: Sandbox failed to execute payload correctly."
  exit 1
fi

# 2. Verificar que no persista el estado en el host
if [ -f "$PAYLOAD_DIR/vuln.txt" ]; then
  echo "ERROR: Sandbox NO ES EFÍMERO. El archivo vuln.txt persistió en el host."
  rm -f "$PAYLOAD_DIR/vuln.txt"
  exit 1
fi

echo "[test] OK: Zero-State Sandboxing funciona y destruye su estado efímero."
exit 0
