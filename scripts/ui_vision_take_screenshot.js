const { chromium } = require("playwright");

async function main() {
    // headless: false forces the browser to actually render on the Xvfb display
    const browser = await chromium.launch({ headless: false });
    const page = await browser.newPage();

    const targetUrl = process.env.DIRECT_CHAT_URL || "http://127.0.0.1:8787/";
    await page.goto(targetUrl, { waitUntil: "domcontentloaded" });

    // Wait for the UI elements to fully render
    await page.waitForTimeout(3000);

    await page.screenshot({ path: "DOCS/RUNS/ui_screenshot.png", fullPage: true });
    await browser.close();
}

main().catch(err => {
    console.error("Screenshot failed:", err);
    process.exit(1);
});
