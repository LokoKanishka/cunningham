# Handoff Continuation Tasks

## 1. Fix Human Mode violations in UI scripts
- [x] `ui_stress_recipes_and_convos.js`: replaced `input.fill()` with `typeHuman()`
- [x] `ui_web_search_questions.js`: replaced raw `click+pressSequentially` with `typeHuman()` + fixed `ensureCheckbox`

## 2. Harden sandbox timeouts in `antigravity/app.py`
- [x] Raised `DEFAULT_TIMEOUT_S` from 30 → 120
- [x] Raised `MAX_TIMEOUT_S` from 30 → 300

## 3. Harden `_guard_code` in `antigravity/app.py`
- [x] Permit `subprocess` and `import` (fix "Lobotomy" Red Flag)
- [x] Block dangerous bash patterns (`rm -rf /`, `mkfs`, etc.)
- [x] Block interactive calls (`os.system`, `os.popen`, `exec`, `eval`)
- [x] Kept existing `rm -rf /` block

## 4. Verification
- [x] Grep for `.fill(` returns zero matches across all JS scripts
- [x] `_guard_code` correctly allows `subprocess` but blocks `rm -rf /`
- [x] `verify_capabilities.sh` - confirm DESKTOP_OK and HANDS_OK
