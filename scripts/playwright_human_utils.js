"use strict";

/**
 * Shared utility for robust human-like Playwright interactions.
 * strict mode: no cheats (fill/eval), but robust retries and diagnostics.
 */

const fs = require('fs');

async function safeScreenshot(page, label) {
    try {
        const ts = Date.now();
        const p = `error_screenshot_${label}_${ts}.png`;
        await page.screenshot({ path: p, fullPage: true });
        console.error(`[DIAGNOSTIC] Screenshot saved to ${p}`);
        return p;
    } catch (e) {
        return "screenshot_failed";
    }
}

/**
 * Types text into a locator one character at a time, like a human.
 * Includes retries for clicking/focusing and error diagnostics.
 * NEVER falls back to fill().
 */
async function humanType(page, locator, text, options = {}) {
    const {
        delay = 35,
        retries = 3,
        name = "unknown_input"
    } = options;

    let lastError = null;

    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            // 1. Ensure visible and enabled
            if (!(await locator.isVisible())) {
                throw new Error("Element not visible");
            }
            if (!(await locator.isEnabled())) {
                throw new Error("Element not enabled");
            }

            // 2. Click to focus (handle potential overlays/toasts by retrying the click)
            await locator.click({ timeout: 2000 });

            // 3. Clear existing content manually if needed (Ctrl+A -> Backspace)
            // This is "human" way to clear, vs .fill('')
            await page.keyboard.press('Control+A');
            await page.keyboard.press('Backspace');

            // 4. Type sequentially
            await page.keyboard.type(text, { delay });

            return; // Success
        } catch (err) {
            console.warn(`[WARN] humanType attempt ${attempt}/${retries} failed for '${name}': ${err.message}`);
            lastError = err;

            if (attempt < retries) {
                await safeScreenshot(page, `type_fail_${name}_${attempt}`);
                // Wait/Backoff before retry
                await page.waitForTimeout(1000 * attempt);
            }
        }
    }

    // If we're here, all retries failed.
    await safeScreenshot(page, `type_fatal_${name}`);
    throw new Error(`humanType failed permanently for '${name}' after ${retries} attempts. Last error: ${lastError.message}`);
}

/**
 * Robustly checks or unchecks a checkbox/radio/switch using locator.check/uncheck.
 * These are valid UI interactions (Playwright ensures visibility/actionability).
 */
async function humanCheck(page, locator, checked, options = {}) {
    const { name = "checkbox" } = options;
    try {
        if (checked) {
            await locator.check({ timeout: 5000 });
        } else {
            await locator.uncheck({ timeout: 5000 });
        }
    } catch (err) {
        console.error(`[ERROR] humanCheck failed for '${name}': ${err.message}`);
        await safeScreenshot(page, `check_fail_${name}`);
        throw err;
    }
}

module.exports = {
    humanType,
    humanCheck
};
