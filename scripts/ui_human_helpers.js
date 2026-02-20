const fs = require("fs");
const path = require("path");

// Elegimos RUNS_DIR si existe; si no, caemos a /tmp.
function getRunsDir() {
    const env = process.env.RUNS_DIR || process.env.OPENCLAW_RUNS_DIR;
    const base = env && env.trim() ? env : "/tmp/openclaw_runs";
    if (!fs.existsSync(base)) fs.mkdirSync(base, { recursive: true });
    return base;
}

function ts() {
    return new Date().toISOString().replace(/[:.]/g, "-");
}

async function diagnose(page, tag) {
    const runs = getRunsDir();
    const dir = path.join(runs, `ui_diag_${tag}_${ts()}`);
    fs.mkdirSync(dir, { recursive: true });

    // screenshot
    try {
        await page.screenshot({ path: path.join(dir, "page.png"), fullPage: true });
    } catch (e) { }

    // html snapshot (ojo: puede ser grande; igual es oro para debug)
    try {
        const html = await page.content();
        fs.writeFileSync(path.join(dir, "page.html"), html, "utf8");
    } catch (e) { }

    // url
    try {
        fs.writeFileSync(path.join(dir, "url.txt"), page.url(), "utf8");
    } catch (e) { }

    return dir;
}

async function assertInteractable(locator, what) {
    // precondiciones duras: visible + enabled + editable si aplica
    if (!(await locator.isVisible())) throw new Error(`[UI] ${what}: not visible`);
    if (!(await locator.isEnabled())) throw new Error(`[UI] ${what}: not enabled`);
    // elementHandle.isEditable() exists in Playwright, locator.isEditable() also exists.
    try {
        if (!(await locator.isEditable())) throw new Error(`[UI] ${what}: not editable`);
    } catch (_) {
        // ignore
    }
}

// Reintentos cortos, sin "taparlo" con fallback a fill()
async function typeHuman(page, locator, text, opts = {}) {
    const {
        delayMs = 35,
        retries = 2,
        retryWaitMs = 250,
        tag = "typeHuman",
    } = opts;

    let lastErr = null;

    for (let attempt = 1; attempt <= retries + 1; attempt++) {
        try {
            await assertInteractable(locator, "input");
            await locator.click({ timeout: 2000 }); // foco real

            // chequeo anti-modal básico: si hay un dialog visible, lo tratamos como bloqueo real
            const modal = page.locator('dialog:visible,[role="dialog"]:visible,.modal:visible,.MuiDialog-root:visible');
            if (await modal.count()) {
                throw new Error("[UI] modal/dialog visible (blocked)");
            }

            await locator.pressSequentially(text, { delay: delayMs });
            return;
        } catch (e) {
            lastErr = e;
            // reintento solo si parece transitorio
            const msg = String(e && e.message ? e.message : e);
            const transient =
                msg.includes("Timeout") ||
                msg.includes("not visible") ||
                msg.includes("not enabled") ||
                msg.includes("Element is not") ||
                msg.includes("Target closed");

            if (attempt <= retries + 0 && transient) {
                await page.waitForTimeout(retryWaitMs);
                continue;
            }

            const dir = await diagnose(page, tag);
            throw new Error(`${msg}\n[UI_DIAG] ${dir}`);
        }
    }

    // no debería llegar
    const dir = await diagnose(page, tag);
    throw new Error(`${String(lastErr)}\n[UI_DIAG] ${dir}`);
}

async function checkUi(locator, opts = {}) {
    const { tag = "checkUi" } = opts;
    try {
        await locator.check({ timeout: 2000 }); // UI-level robusto (no es “API interna”)
    } catch (e) {
        // Acá no tenemos page asegurado, así que devolvemos error claro.
        throw new Error(`[UI] ${tag}: check() failed: ${String(e && e.message ? e.message : e)}`);
    }
}

module.exports = {
    typeHuman,
    checkUi,
};
