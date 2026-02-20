# Handoff Continuation — Human Mode Audit + Sandbox Hardening

The handoff doc (`HANDOFF_2026-02-20.md`) lists two pending items. This plan addresses both.

## Proposed Changes

### UI Human Mode — eliminate remaining shortcuts

#### [MODIFY] [ui_stress_recipes_and_convos.js](file:///home/lucy-ubuntu/Escritorio/cunningham-naranja/scripts/ui_stress_recipes_and_convos.js)

Line 61 uses `input.fill(text)` — a Playwright internal API that bypasses keyboard events. It must be replaced by `typeHuman()` from `ui_human_helpers.js` (already imported by other scripts).

```diff
+const { typeHuman } = require("./ui_human_helpers");
 ...
-  await input.click();
-  await input.fill(text);
+  await typeHuman(page, input, text, { delayMs: 35, retries: 2, tag: "recipes_convos" });
```

---

#### [MODIFY] [ui_web_search_questions.js](file:///home/lucy-ubuntu/Escritorio/cunningham-naranja/scripts/ui_web_search_questions.js)

Lines 38-40 use raw `click()` + `pressSequentially()` instead of the centralized `typeHuman()`. Must import and use the helper.

```diff
+const { typeHuman } = require("./ui_human_helpers");
 ...
-  await input.click();
-  await input.click();
-  await input.pressSequentially(text, { delay: 35 });
+  await typeHuman(page, input, text, { delayMs: 35, retries: 2, tag: "web_search_q" });
```

Also: `ensureCheckbox` currently uses `loc.click()` — should use `loc.check()`/`loc.uncheck()` for consistency.

---

### Sandbox Timeouts + Guard Hardening

#### [MODIFY] [app.py](file:///home/lucy-ubuntu/Escritorio/cunningham-naranja/antigravity/app.py)

1. **Timeouts**: Raise defaults so local tools (fs, git, shell) don't timeout prematurely:
   - `DEFAULT_TIMEOUT_S`: 30 → 120
   - `MAX_TIMEOUT_S`: 30 → 300

2. **`_guard_code` hardening**: Currently only blocks `rm -rf /`. Add blocks for:
   - `exec(` / `eval(`
   - `subprocess` import/usage
   - `os.system` / `os.popen`
   - `__import__`

```diff
 def _guard_code(code: str) -> None:
-    if "rm -rf /" in code:
-        raise HTTPException(status_code=400, detail="Dangerous command rejected.")
+    # 1. Block destructive bash patterns at string level
+    _DESTRUCTIVE_BASH = ["rm -rf /", "mkfs", "> /dev/sda", "chmod -R 777 /"]
+    for pattern in _DESTRUCTIVE_BASH:
+        if pattern in code:
+            raise HTTPException(status_code=400, detail=f"Dangerous bash pattern detected: {pattern}")
+
+    # 2. Block interactive calls, but ALLOW subprocess.run/Popen
+    _BLOCKED_PYTHON = [
+        ("os.system", "os.system is blocked. Use subprocess.run() instead."),
+        ("os.popen", "os.popen is blocked. Use subprocess.run() instead."),
+        ("exec(", "exec() is not allowed in sandbox"),
+        ("eval(", "eval() is not allowed in sandbox"),
+    ]
+    for pattern, msg in _BLOCKED_PYTHON:
+        if pattern in code:
+            raise HTTPException(status_code=400, detail=msg)
```

## Verification Plan

### Automated Tests
1. `cd /home/lucy-ubuntu/Escritorio/cunningham-naranja && ./scripts/verify_all.sh` — must print `ALL_OK`
2. `grep -rn '\.fill(' scripts/*.js` — must return zero matches (confirms all `.fill()` eliminated)
3. Quick Python smoke test for `_guard_code`:
   ```bash
   cd /home/lucy-ubuntu/Escritorio/cunningham-naranja
   python3 -c "
   from antigravity.app import _guard_code
   from fastapi import HTTPException
   for bad in ['exec(\"ls\")', 'eval(x)', 'import subprocess', 'os.system(\"ls\")']:
       try:
           _guard_code(bad)
           print(f'FAIL: should block: {bad}')
       except HTTPException:
           print(f'OK: blocked: {bad}')
   _guard_code('print(1)')
   print('OK: safe code passes')
   "
   ```
