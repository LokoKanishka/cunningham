const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    const base = 'http://localhost:5678';

    console.log('Navigating to setup...');
    await page.goto(`${base}/owner/setup`, { waitUntil: 'networkidle' });

    // Si ya existe redirección, es que ya está seteado o en signin
    if (page.url().includes('signin')) {
        console.log('Already set up, proceeding to sign in...');
    } else {
        console.log('Performing initial owner setup...');
        await page.fill('input[name="email"]', 'lucy@trident.local');
        await page.fill('input[name="firstName"]', 'Lucy');
        await page.fill('input[name="lastName"]', 'Tridente');
        await page.fill('input[name="password"]', 'Tridente2026!');
        await page.click('button:has-text("Next"), button:has-text("Siguiente")');
        await page.waitForTimeout(2000);
        // Skip personalization
        try {
            await page.click('button:has-text("Skip"), button:has-text("Omitir")', { timeout: 5000 });
        } catch (e) { }
    }

    console.log('Navigating to workflow list...');
    await page.goto(`${base}/home/workflows`, { waitUntil: 'networkidle' });

    // Refrescar para asegurar que los imports (que hice vía CLI) se vean
    await page.reload({ waitUntil: 'networkidle' });

    const wf = page.locator('text=/Cerebro_Voz_Gamma/i').first();
    if (await wf.count() === 0) {
        console.log('Workflow not found in UI, attempting re-import via UI...');
        // Subir archivo si es necesario, pero ya debería estar en la DB si el CLI funcionó
        // Si el CLI falló por falta de usuario, lo intentamos ahora que hay usuario
    } else {
        await wf.click();
        await page.waitForLoadState('networkidle');

        const activeSwitch = page.locator('.active-switch, [role="switch"]').first();
        const isActive = await activeSwitch.getAttribute('aria-checked');
        if (isActive !== 'true') {
            console.log('Turning workflow ON...');
            await activeSwitch.click();
            await page.waitForTimeout(2000);
        } else {
            console.log('Workflow already active.');
        }
    }

    await page.screenshot({ path: 'n8n_activation_result.png', fullPage: true });
    console.log('Done.');
    await browser.close();
})().catch(err => {
    console.error('ERROR:', err);
    process.exit(1);
});
