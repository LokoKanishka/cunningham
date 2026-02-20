#!/usr/bin/env bash
set -euo pipefail

# ui_vision_assert.sh — Horizonte Verde E3: Assertions de UI Basadas en Visión
# Toma una captura de pantalla del frontend renderizado en Xvfb y usa OCR
# para garantizar que el texto principal sea visible a ojos de un humano.

TARGET_URL="${DIRECT_CHAT_URL:-http://127.0.0.1:8787/}"
IMG="DOCS/RUNS/ui_screenshot.png"
mkdir -p DOCS/RUNS
rm -f "$IMG"

echo "[vision-assert] Launching browser in isolated Xvfb display..."
# Ejecutamos el script de captura usando display_isolation para evitar parpadeos
./scripts/display_isolation.sh run headless -- node scripts/ui_vision_take_screenshot.js

if [ ! -f "$IMG" ]; then
  echo "ERROR: Screenshot NO generada en $IMG" >&2
  exit 1
fi

echo "[vision-assert] Running OCR via local_vision.sh stack..."
# Validar primero si local_vision.sh dice que OCR (tesseract) está disponible
if ! ./scripts/local_vision.sh check | grep -q "LOCAL_VISION_OK:tesseract"; then
  echo "SKIP: Tesseract OCR no está disponible o instalado. Omitiendo la aserción semántica."
  echo "UI_VISION_ASSERT_SKIPPED"
  exit 0
fi

ocr_text="$(./scripts/local_vision.sh image "$IMG")"

echo "[vision-assert] OCR output preview:"
echo "$ocr_text" | head -n 15 | sed 's/^/  /'

echo "[vision-assert] Validating semantic presence..."
ERRORS=0

if ! echo "$ocr_text" | grep -iq "Molbot"; then
  echo "ASSERT ERROR: 'Molbot' NOT found in visual render."
  ERRORS=$((ERRORS + 1))
fi

if ! echo "$ocr_text" | grep -iq "Enviar"; then
  echo "ASSERT ERROR: 'Enviar' button NOT found in visual render."
  ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "UI_VISION_ASSERT_FAIL: $ERRORS assertions broken on visual render ($TARGET_URL)"
  exit 1
fi

echo "UI_VISION_ASSERT_OK"
exit 0
